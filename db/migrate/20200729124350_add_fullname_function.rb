class AddFullnameFunction < ActiveRecord::Migration[4.2]
  def change
    execute <<-SQL
      create or replace function public.set_full_name()
      returns trigger as
      $function$

      declare new_fullname varchar;

      begin
          new_fullname := UNACCENT(TRIM(coalesce(new.first_name, '') || ' ' || coalesce(new.last_name, '')));

        if (coalesce(new.fullname, '') <> new_fullname) then
          update users set fullname = new_fullname
          where id = new.id;
        end if;
        RETURN null;
      end;
      $function$
      language plpgsql;

      drop trigger if exists set_full_name_trigger on users;
      create trigger set_full_name_trigger
      after insert or update on users
      for each row execute procedure public.set_full_name();
    SQL
  end
end
