
-- Crear vista y relacionar tablas

CREATE VIEW [dbo].[vista_analítica_main] AS

SELECT s.set_num, s.name as set_name, s.year, s.theme_id, cast(s.num_parts as numeric) num_parts, t.name as theme_name, t.parent_id, p.name as parent_theme_name
FROM dbo.sets s
left join [dbo].[themes] t
	on s.theme_id = t.id
left join [dbo].[themes] p
	on t.parent_id = p.id;

SELECT * FROM vista_analítica_main;

-- ###################################################################################################################################################################################

-- 1.¿Cuál es el número total de partes por cada tema?

select theme_name as Temática, SUM(num_parts) as Número_total_de_piezas
from dbo.vista_analítica_main
-- where parent_theme_name is not NULL
group by theme_name
order by 2 desc;

-- ###################################################################################################################################################################################

-- 2.¿Cuál es el número total de piezas por año?

select year as Año, SUM(num_parts) as Número_total_de_piezas
from dbo.vista_analítica_main
-- where parent_theme_name is not NULL
group by year
order by 2 desc;

-- ###################################################################################################################################################################################

-- 3. ¿Cuántos sets de Lego se han lanzado por cada siglo?

SELECT (LEFT(year, 2)+1) AS Siglo, COUNT(set_name) as Número_total_de_sets_lanzados
from vista_analítica_main
-- where parent_theme_name is not NULL
group by (LEFT(year, 2)+1);

-- ###################################################################################################################################################################################

-- 4.¿Qué porcentaje de los sets realizados en el siglo 21 tenián como temática trenes?

;with siglo21_porTematica as
(
	SELECT theme_name, COUNT(set_num) as numero_total_sets
	from vista_analítica_main
	where (LEFT(year, 2)+1) = 21
	group by theme_name
	)

SELECT SUM(numero_total_sets) as Número_total_de_sets_lanzados, SUM(Porcentaje) as Porcentaje_del_total
from (
	SELECT theme_name, numero_total_sets, SUM(numero_total_sets) OVER () as Total, ((numero_total_sets * 100.0) /  SUM(numero_total_sets) OVER ()) AS Porcentaje
	from siglo21_porTematica
	)m
where theme_name like '%train%'

-- ###################################################################################################################################################################################

-- 5.¿Cuál fue la temática más popular de cada año del siglo 21 en términos de sets lanzados?

SELECT year, theme_name as temática_más_popular, numero_total_sets
from (
	SELECT year, theme_name, COUNT(set_num) as numero_total_sets, ROW_NUMBER() OVER(Partition by year order by COUNT(set_num) desc) AS ranking
	from vista_analítica_main
	where (LEFT(year, 2)+1) = 21
	-- and parent_theme_name is not NULL
	group by year, theme_name
	)m
WHERE ranking = 1
order by year desc;

-- ###################################################################################################################################################################################

-- 6. ¿Cuál es el color más producido en términos de cantidad de piezas de ese color lanzadas?

SELECT Color, SUM(quantity) as Cantidad_de_piezas_lanzadas
from (select i.color_id, i.inventory_id, i.part_num, cast(i.quantity as numeric) quantity, i.is_spare, c.name as color, c.rgb, p.name as part_name, p.part_material, pc.name as category_name 
from inventory_parts i
inner join colors c
	on i.color_id = c.id
inner join parts p
	on i.part_num = p.part_num
inner join part_categories pc
	on p.part_cat_id = pc.id
	)m
group by color
order by Cantidad_de_piezas_lanzadas desc
