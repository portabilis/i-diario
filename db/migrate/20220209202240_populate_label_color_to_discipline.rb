class PopulateLabelColorToDiscipline < ActiveRecord::Migration[4.2]
  def change
    ActiveRecord::Base.connection.execute(
      <<-SQL
        CREATE OR REPLACE FUNCTION random_color_pick()
          RETURNS text AS
        $func$
        DECLARE
          a text[] := '{#1C1C1C,#363636,#4F4F4F,#696969,#808080,#A9A9A9,#6A5ACD,#836FFF,#6959CD,#483D8B,#191970,#000080,#0000CD,#6495ED,#4169E1,#1E90FF,#00BFFF,#87CEFA,#87CEEB,#4682B4,#00CED1,#40E0D0,#48D1CC,#20B2AA,#008B8B,#66CDAA,#5F9EA0,#8FBC8F,#3CB371,#2E8B57,#006400,#008000,#32CD32,#9ACD32,#6B8E23,#556B2F,#808000,#BDB76B,#DAA520,#B8860B,#8B4513,#A0522D,#BC8F8F,#CD853F,#D2691E,#F4A460,#DEB887,#7B68EE,#9370DB,#8A2BE2,#4B0082,#9400D3,#BA55D3,#8B008B,#EE82EE,#DA70D6,#DDA0DD,#C71585,#FF69B4,#DB7093,#FFB6C1,#F08080,#CD5C5C,#DC143C,#800000,#B22222,#FA8072,#E9967A,#FF7F50,#FF6347,#FF4500,#FFA500,#FFD700,1}';
        BEGIN
          RETURN a[floor((random() * array_length(a, 1)))::int];
        END
        $func$ LANGUAGE plpgsql VOLATILE;

        update disciplines set label_color = random_color_pick();

        DROP FUNCTION random_color_pick();
      SQL
    )
  end
end
