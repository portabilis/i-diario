module Api
  module V2
    class DailyPhysicalFrequenciesController < Api::V2::BaseController
      before_action :authenticate_api!

      def index
        paginated_records = paginate_records(filtered_records)

        render json: {
          data: serialize_records(paginated_records),
          pagination: pagination_metadata(paginated_records)
        }, status: :ok
      end

      def create
        unless params[:_json].present? && params[:_json].is_a?(Array)
          return render json: { error: "Payload deve ser um array válido" }, status: :bad_request
        end

        unity_api_codes = batch_params.map { |p| p[:unity_api_code] }.uniq
        enrollment_api_codes = batch_params.map { |p| p[:student_enrollment_api_code] }.uniq

        unities = Unity.where(api_code: unity_api_codes).index_by(&:api_code)
        student_enrollments = StudentEnrollment.where(api_code: enrollment_api_codes).index_by(&:api_code)

        frequencies_to_create = []
        errors = []

        batch_params.each_with_index do |frequency_params, index|
          unity = unities[frequency_params[:unity_api_code]]
          student_enrollment = student_enrollments[frequency_params[:student_enrollment_api_code]]

          if unity.nil? || student_enrollment.nil?
            errors << { record: index, error: "Unidade com api_code '#{frequency_params[:unity_api_code]}' não encontrada." } if unity.nil?
            errors << { record: index, error: "Matrícula com api_code '#{frequency_params[:student_enrollment_api_code]}' não encontrada." } if student_enrollment.nil?
            next
          end

          daily_physical_frequency = DailyPhysicalFrequency.find_or_initialize_by(
            unity_id: unity.id,
            student_enrollment_id: student_enrollment.id,
            frequency_date: frequency_params[:frequency_date]
          )

          daily_physical_frequency.assign_attributes(
            present: frequency_params[:present]
          )

          unless daily_physical_frequency.valid?
            errors << { record: index, error: daily_physical_frequency.errors.full_messages }
          end

          frequencies_to_create << daily_physical_frequency
        end

        return render json: { errors: errors }, status: :unprocessable_entity if errors.any?

        begin
          ActiveRecord::Base.transaction do
            frequencies_to_create.each(&:save!)
          end
          render json: { status: 'success', created_count: frequencies_to_create.size }, status: :created
        rescue ActiveRecord::RecordInvalid => e
          render json: { errors: [e.message] }, status: :unprocessable_entity
        end
      end

      private

      def filtered_records
        DailyPhysicalFrequency.includes(:unity, :student_enrollment)
                              .by_unity_api_code(filter_params[:unity_api_code])
                              .by_student_enrollment_api_code(filter_params[:student_enrollment_api_code])
                              .by_frequency_date(filter_params[:frequency_date])
      end

      def paginate_records(records)
        records.page(pagination_params[:page]).per(pagination_params[:per_page])
      end

      def serialize_records(records)
        records.map do |record|
          {
            id: record.id,
            student_enrollment_api_code: record.student_enrollment.api_code,
            unity_api_code: record.unity.api_code,
            frequency_date: record.frequency_date,
            present: record.present,
            created_at: record.created_at,
            updated_at: record.updated_at
          }
        end
      end

      def pagination_metadata(paginated_records)
        {
          current_page: paginated_records.current_page,
          total_pages: paginated_records.total_pages,
          total_count: paginated_records.total_count,
          per_page: paginated_records.limit_value,
          next_page: paginated_records.next_page,
          prev_page: paginated_records.prev_page
        }
      end

      def pagination_params
        {
          page: params[:page] || 1,
          per_page: [params[:per_page]&.to_i || 25, 100].min
        }
      end

      def filter_params
        params.permit(:unity_api_code, :student_enrollment_api_code, :frequency_date, :page, :per_page)
      end

      def batch_params
        params.permit(_json: [:unity_api_code, :student_enrollment_api_code, :frequency_date, :present])
              .require(:_json)
      end
    end
  end
end
