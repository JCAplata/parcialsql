-------------------------------------------------------------------------------------------------------
--1. InformeAlquileresMensual: Genera un informe mensual de alquileres y lo almacena automáticamente.
-------------------------------------------------------------------------------------------------------

DELIMITER $$

CREATE EVENT InformeAlquileresMensual
ON SCHEDULE EVERY 1 MONTH
STARTS (TIMESTAMP(CURRENT_DATE + INTERVAL 1 DAY) + INTERVAL 0 HOUR) -- se ejecuta el primer día del mes siguiente
DO
BEGIN
    INSERT INTO informe_alquileres_mensual (
        mes,
        mes_numero,
        total_alquileres,
        total_ingresos
    )
    SELECT
        YEAR(fecha_alquiler) AS año,
        MONTH(fecha_alquiler) AS mes,
        COUNT(*) AS total_alquileres,
        IFNULL(SUM(p.total), 0) AS total_ingresos
    FROM alquiler a
    LEFT JOIN pago p ON a.id_alquiler = p.id_alquiler
    WHERE 
        fecha_alquiler >= DATE_FORMAT(CURRENT_DATE - INTERVAL 1 MONTH, '%Y-%m-01')
        AND fecha_alquiler <  DATE_FORMAT(CURRENT_DATE, '%Y-%m-01')
    GROUP BY año, mes;
END$$

DELIMITER ;


--------------------------------------------------------------------------------------------------------------
--2. ActualizarSaldoPendienteCliente: Actualiza los saldos pendientes de los clientes al final de cada mes.
--------------------------------------------------------------------------------------------------------------

DELIMITER $$

CREATE EVENT ActualizarSaldoPendienteCliente
ON SCHEDULE EVERY 1 MONTH
STARTS (TIMESTAMP(CURRENT_DATE + INTERVAL 1 DAY) + INTERVAL 0 HOUR) -- ejecuta el día 1 de cada mes
DO
BEGIN
    -- Actualiza o inserta el saldo pendiente por cliente
    REPLACE INTO saldo_pendiente_cliente (id_cliente, saldo)
    SELECT 
        c.id_cliente,
        IFNULL(SUM(CASE 
            WHEN p.id_pago IS NULL THEN 1
            ELSE 0
        END), 0) * 4.99 AS saldo_aproximado -- o el monto por alquiler estimado si no hay pago
    FROM 
        cliente c
    LEFT JOIN 
        alquiler a ON c.id_cliente = a.id_cliente
    LEFT JOIN 
        pago p ON a.id_alquiler = p.id_alquiler
    GROUP BY 
        c.id_cliente;
END$$

DELIMITER ;

---------------------------------------------------------------------------------------------------------------
--3. AlertaPeliculasNoAlquiladas: Envía una alerta cuando una película no ha sido alquilada en el último año.
---------------------------------------------------------------------------------------------------------------

DELIMITER $$

CREATE EVENT AlertaPeliculasNoAlquiladas
ON SCHEDULE EVERY 1 MONTH
STARTS (TIMESTAMP(CURRENT_DATE + INTERVAL 1 DAY) + INTERVAL 0 HOUR)
DO
BEGIN
    INSERT INTO alerta_peliculas_no_alquiladas (id_pelicula, titulo)
    SELECT 
        p.id_pelicula,
        p.titulo
    FROM 
        pelicula p
    LEFT JOIN 
        inventario i ON p.id_pelicula = i.id_pelicula
    LEFT JOIN 
        alquiler a ON i.id_inventario = a.id_inventario
        AND a.fecha_alquiler >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR)
    WHERE 
        a.id_alquiler IS NULL;
END$$

DELIMITER ;


----------------------------------------------------------------------------------------------
--4. LimpiarAuditoriaCada6Meses: Borra los registros antiguos de auditoría cada seis meses.
----------------------------------------------------------------------------------------------

DELIMITER $$

CREATE EVENT LimpiarAuditoriaCada6Meses
ON SCHEDULE EVERY 6 MONTH
STARTS (TIMESTAMP(CURRENT_DATE + INTERVAL 1 DAY))
DO
BEGIN
    DELETE FROM auditoria_cliente
    WHERE fecha_modificacion < DATE_SUB(CURDATE(), INTERVAL 1 YEAR);
END$$

DELIMITER ;

-----------------------------------------------------------------------------------------------------------
--5. ActualizarCategoriasPopulares: Actualiza la lista de categorías más alquiladas al final de cada mes.
-----------------------------------------------------------------------------------------------------------

DELIMITER $$

CREATE EVENT ActualizarCategoriasPopulares
ON SCHEDULE EVERY 1 MONTH
STARTS (TIMESTAMP(CURRENT_DATE + INTERVAL 1 DAY))
DO
BEGIN
    DELETE FROM categorias_populares
    WHERE mes = YEAR(CURRENT_DATE - INTERVAL 1 MONTH)
      AND mes_numero = MONTH(CURRENT_DATE - INTERVAL 1 MONTH);

    INSERT INTO categorias_populares (mes, mes_numero, id_categoria, nombre_categoria, total_alquileres)
    SELECT 
        YEAR(a.fecha_alquiler) AS año,
        MONTH(a.fecha_alquiler) AS mes,
        c.id_categoria,
        c.nombre,
        COUNT(*) AS total_alquileres
    FROM alquiler a
    JOIN inventario i ON a.id_inventario = i.id_inventario
    JOIN pelicula_categoria pc ON i.id_pelicula = pc.id_pelicula
    JOIN categoria c ON pc.id_categoria = c.id_categoria
    WHERE a.fecha_alquiler >= DATE_FORMAT(CURRENT_DATE - INTERVAL 1 MONTH, '%Y-%m-01')
      AND a.fecha_alquiler <  DATE_FORMAT(CURRENT_DATE, '%Y-%m-01')
    GROUP BY c.id_categoria, c.nombre;
END$$

DELIMITER ;
