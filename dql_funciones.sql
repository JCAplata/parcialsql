-----------------------------------------------------------------------------------------------------------------
--1. TotalIngresosCliente(ClienteID, Año): Calcula los ingresos generados por un cliente en un año específico.
-----------------------------------------------------------------------------------------------------------------

DELIMITER $$

CREATE FUNCTION TotalIngresosCliente(p_ClienteID SMALLINT UNSIGNED, p_Año YEAR)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE total_ingresos DECIMAL(10,2);

    SELECT 
        IFNULL(SUM(p.total), 0)
    INTO 
        total_ingresos
    FROM 
        pago p
    JOIN 
        alquiler a ON p.id_alquiler = a.id_alquiler
    WHERE 
        a.id_cliente = p_ClienteID
        AND YEAR(p.fecha_pago) = p_Año;

    RETURN total_ingresos;
END$$

DELIMITER ;


-----------------------------------------------------------------------------------------------------------------
--2. PromedioDuracionAlquiler(PeliculaID): Retorna la duración promedio de alquiler de una película específica.
-----------------------------------------------------------------------------------------------------------------

DELIMITER $$

CREATE FUNCTION PromedioDuracionAlquiler(p_PeliculaID SMALLINT UNSIGNED)
RETURNS DECIMAL(5,2)
DETERMINISTIC
BEGIN
    DECLARE promedio_duracion DECIMAL(5,2);

    SELECT 
        IFNULL(AVG(DATEDIFF(a.fecha_devolucion, a.fecha_alquiler)), 0)
    INTO 
        promedio_duracion
    FROM 
        alquiler a
    JOIN 
        inventario i ON a.id_inventario = i.id_inventario
    WHERE 
        i.id_pelicula = p_PeliculaID
        AND a.fecha_devolucion IS NOT NULL;

    RETURN promedio_duracion;
END$$

DELIMITER ;

---------------------------------------------------------------------------------------------------------------------------
--3. IngresosPorCategoria(CategoriaID): Calcula los ingresos totales generados por una categoría específica de películas.
---------------------------------------------------------------------------------------------------------------------------

DELIMITER $$

CREATE FUNCTION IngresosPorCategoria(p_CategoriaID TINYINT UNSIGNED)
RETURNS DECIMAL(15,2)
DETERMINISTIC
BEGIN
    DECLARE total_ingresos DECIMAL(15,2);

    SELECT 
        IFNULL(SUM(p.total), 0)
    INTO 
        total_ingresos
    FROM 
        pago p
    JOIN 
        alquiler a ON p.id_alquiler = a.id_alquiler
    JOIN 
        inventario i ON a.id_inventario = i.id_inventario
    JOIN 
        pelicula_categoria pc ON i.id_pelicula = pc.id_pelicula
    WHERE 
        pc.id_categoria = p_CategoriaID;

    RETURN total_ingresos;
END$$

DELIMITER ;

---------------------------------------------------------------------------------------------------------------------
--4. DescuentoFrecuenciaCliente(ClienteID): Calcula un descuento basado en la frecuencia de alquiler del cliente.
---------------------------------------------------------------------------------------------------------------------

DELIMITER $$

CREATE FUNCTION DescuentoFrecuenciaCliente(p_ClienteID SMALLINT UNSIGNED)
RETURNS DECIMAL(4,2)
DETERMINISTIC
BEGIN
    DECLARE num_alquileres INT;
    DECLARE descuento DECIMAL(4,2);

    SELECT 
        COUNT(*) 
    INTO 
        num_alquileres
    FROM 
        alquiler
    WHERE 
        id_cliente = p_ClienteID;

    IF num_alquileres < 5 THEN
        SET descuento = 0.00;
    ELSEIF num_alquileres BETWEEN 5 AND 10 THEN
        SET descuento = 0.05; -- 5%
    ELSE
        SET descuento = 0.10; -- 10%
    END IF;

    RETURN descuento;
END$$

DELIMITER ;

-------------------------------------------------------------------------------------------------------------------------------------------
--5. EsClienteVIP(ClienteID): Verifica si un cliente es "VIP" basándose en la cantidad de alquileres realizados y los ingresos generados.
-------------------------------------------------------------------------------------------------------------------------------------------

DELIMITER $$

CREATE FUNCTION EsClienteVIP(p_ClienteID SMALLINT UNSIGNED)
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
    DECLARE total_alquileres INT;
    DECLARE total_ingresos DECIMAL(15,2);

    -- Contar número de alquileres
    SELECT 
        COUNT(*)
    INTO 
        total_alquileres
    FROM 
        alquiler
    WHERE 
        id_cliente = p_ClienteID;

    -- Sumar ingresos generados
    SELECT 
        IFNULL(SUM(p.total), 0)
    INTO 
        total_ingresos
    FROM 
        pago p
    JOIN 
        alquiler a ON p.id_alquiler = a.id_alquiler
    WHERE 
        a.id_cliente = p_ClienteID;

    IF total_alquileres > 20 AND total_ingresos > 1000 THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;

END$$

DELIMITER ;
