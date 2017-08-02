namespace :migration do
  desc "Migrate ***REMOVED***s and Menus"
  task ***REMOVED***_and_***REMOVED***s: :environment do
    Entity.all.each do |entity|
      entity.using_connection do
        Menu.all.each do |***REMOVED***|
          recipe = ***REMOVED***.new(
            description: ***REMOVED***.description,
            yield: 1,
            created_at: ***REMOVED***.created_at,
            updated_at: ***REMOVED***.updated_at
          )

          ***REMOVED***.food_***REMOVED***s.each do |food_***REMOVED***|
            recipe.ingredients.new(
              material: food_***REMOVED***.food.food_***REMOVED***.first.material,
              food: food_***REMOVED***.food,
              gross_weight: (food_***REMOVED***.quantity * 100),
              created_at: food_***REMOVED***.created_at,
              updated_at: food_***REMOVED***.updated_at
            )
          end

          recipe.save

          weekdays = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']
          ***REMOVED*** = ***REMOVED***.where(***REMOVED***_id: ***REMOVED***.id).select(:weekdays)
          ***REMOVED***_***REMOVED***_type = ***REMOVED***.***REMOVED***_***REMOVED***.new(***REMOVED***_type: ***REMOVED***.***REMOVED***_type)
          Workdays.list.each do |weekday|
            ***REMOVED***_***REMOVED***_type_weekday = ***REMOVED***_***REMOVED***_type.***REMOVED***_***REMOVED***_type_weekdays.new(weekday: weekday)

            if ***REMOVED***.select { |c| c.weekdays.include?(weekdays.index(weekday).to_s) }.count > 0
              ***REMOVED***_***REMOVED***_type_weekday.***REMOVED*** << recipe
            end
          end

          ***REMOVED***_***REMOVED***_type.save
        end
      end
    end
  end
end
