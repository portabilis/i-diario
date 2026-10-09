// Tests for app/assets/javascripts/views/daily_frequencies/new.js
// Covers the pure "Aula" filtering logic added for quadro de aulas support:
// classrooms without a lessons board keep the old full class-number list,
// classrooms with one only offer the teacher's actual lessons for the
// selected weekday/discipline.

const {
  dailyFrequencyWeekdayFor,
  computeClassNumbersData
} = require('../../../../app/assets/javascripts/views/daily_frequencies/new');

describe('dailyFrequencyWeekdayFor', () => {
  it('returns the English lowercase weekday name for a dd/mm/yyyy date', () => {
    // 2026-09-29 is a Tuesday
    expect(dailyFrequencyWeekdayFor('29/09/2026')).toBe('tuesday');
    // 2026-10-01 is a Thursday
    expect(dailyFrequencyWeekdayFor('01/10/2026')).toBe('thursday');
  });

  it('returns null for malformed or empty input', () => {
    expect(dailyFrequencyWeekdayFor('')).toBeNull();
    expect(dailyFrequencyWeekdayFor(undefined)).toBeNull();
    expect(dailyFrequencyWeekdayFor('29-09-2026')).toBeNull();
    expect(dailyFrequencyWeekdayFor('not a date')).toBeNull();
  });
});

describe('computeClassNumbersData', () => {
  const allClassNumbersElements = [
    { id: 1, name: 1, text: 1 },
    { id: 2, name: 2, text: 2 },
    { id: 3, name: 3, text: 3 },
    { id: 4, name: 4, text: 4 },
    { id: 5, name: 5, text: 5 }
  ];

  // Mirrors the real "6º ano" / MATEMATICA fixture used to reproduce this
  // feature manually: monday(1,2), thursday(1,5), friday(4).
  const allocations = [
    { classroom_id: 166, discipline_id: 5, weekday: 'monday', lesson_number: 1 },
    { classroom_id: 166, discipline_id: 5, weekday: 'monday', lesson_number: 2 },
    { classroom_id: 166, discipline_id: 5, weekday: 'thursday', lesson_number: 1 },
    { classroom_id: 166, discipline_id: 5, weekday: 'thursday', lesson_number: 5 },
    { classroom_id: 166, discipline_id: 5, weekday: 'friday', lesson_number: 4 },
    // Another discipline, same classroom/weekday — must not leak into the
    // filtered result when a specific discipline is selected.
    { classroom_id: 166, discipline_id: 8, weekday: 'thursday', lesson_number: 3 }
  ];

  const classroomIdsWithBoard = [166, 201];

  it('returns null when classroomId or frequencyDate is missing', () => {
    expect(computeClassNumbersData({
      allocations,
      classroomIdsWithBoard,
      allClassNumbersElements,
      classroomId: '',
      disciplineId: '5',
      frequencyDate: '01/10/2026'
    })).toBeNull();

    expect(computeClassNumbersData({
      allocations,
      classroomIdsWithBoard,
      allClassNumbersElements,
      classroomId: '166',
      disciplineId: '5',
      frequencyDate: ''
    })).toBeNull();
  });

  it('falls back to the full class-number list when the classroom has no lessons board', () => {
    const result = computeClassNumbersData({
      allocations,
      classroomIdsWithBoard,
      allClassNumbersElements,
      classroomId: '999', // not in classroomIdsWithBoard
      disciplineId: '5',
      frequencyDate: '29/09/2026' // Tuesday — would be empty if filtered
    });

    expect(result.elements).toBe(allClassNumbersElements);
    expect(result.emptyByBoard).toBe(false);
  });

  it('filters to only the lessons the teacher has for that classroom/weekday/discipline', () => {
    const result = computeClassNumbersData({
      allocations,
      classroomIdsWithBoard,
      allClassNumbersElements,
      classroomId: '166',
      disciplineId: '5',
      frequencyDate: '01/10/2026' // Thursday -> lessons 1 and 5
    });

    expect(result.elements).toEqual([
      { id: 1, name: '1', text: '1' },
      { id: 5, name: '5', text: '5' }
    ]);
    expect(result.emptyByBoard).toBe(false);
  });

  it('does not mix lessons from a different discipline on the same classroom/weekday', () => {
    const result = computeClassNumbersData({
      allocations,
      classroomIdsWithBoard,
      allClassNumbersElements,
      classroomId: '166',
      disciplineId: '8',
      frequencyDate: '01/10/2026'
    });

    expect(result.elements).toEqual([
      { id: 3, name: '3', text: '3' }
    ]);
  });

  it('ignores the discipline filter when no discipline is selected yet (GENERAL frequency)', () => {
    const result = computeClassNumbersData({
      allocations,
      classroomIdsWithBoard,
      allClassNumbersElements,
      classroomId: '166',
      disciplineId: '',
      frequencyDate: '01/10/2026'
    });

    expect(result.elements.map((el) => el.id)).toEqual([1, 3, 5]);
  });

  it('returns an empty, board-driven result when the classroom has a board but no lesson that day', () => {
    const result = computeClassNumbersData({
      allocations,
      classroomIdsWithBoard,
      allClassNumbersElements,
      classroomId: '166',
      disciplineId: '5',
      frequencyDate: '29/09/2026' // Tuesday — this teacher has nothing that day
    });

    expect(result.elements).toEqual([]);
    expect(result.emptyByBoard).toBe(true);
  });

  it('returns string ids/text even though the source lesson numbers are integers', () => {
    const result = computeClassNumbersData({
      allocations,
      classroomIdsWithBoard,
      allClassNumbersElements,
      classroomId: '166',
      disciplineId: '5',
      frequencyDate: '01/10/2026'
    });

    result.elements.forEach((el) => {
      expect(typeof el.name).toBe('string');
      expect(typeof el.text).toBe('string');
    });
  });
});
