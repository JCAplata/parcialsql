--------------------------------------------------------------------------------------------------------------------------------------------------
--1. ActualizarTotalAlquileresEmpleado: Al registrar un alquiler, actualiza el total de alquileres gestionados por el empleado correspondiente.
--------------------------------------------------------------------------------------------------------------------------------------------------

DELIMITER $$

CREATE TRIGGER ActualizarTotalAlquileresEmpleado
AFTER INSERT ON alquiler
FOR EACH ROW
BEGIN
    -- Si el empleado ya tiene registro, actualizamos el contador
    IF EXISTS (SELECT 1 FROM total_alquileres_empleado WHERE id_empleado = NEW.id_empleado) THEN
        UPDATE total_alquileres_empleado
        SET total_alquileres = total_alquileres + 1
        WHERE id_empleado = NEW.id_empleado;
    ELSE
        -- Si no existe, creamos el registro con total 1
        INSERT INTO total_alquileres_empleado (id_empleado, total_alquileres)
        VALUES (NEW.id_empleado, 1);
    END IF;
END$$

DELIMITER ;


-----------------------------------------------------------------------------------------------------------------------
--2. AuditarActualizacionCliente: Cada vez que se modifica un cliente, registra el cambio en una tabla de auditoría.
-----------------------------------------------------------------------------------------------------------------------

DELIMITER $$

CREATE TRIGGER AuditarActualizacionCliente
BEFORE UPDATE ON cliente
FOR EACH ROW
BEGIN
    INSERT INTO auditoria_cliente (
        id_cliente,
        nombre_anterior,
        apellidos_anterior,
        email_anterior,
        fecha_modificacion
    ) VALUES (
        OLD.id_cliente,
        OLD.nombre,
        OLD.apellidos,
        OLD.email,
        NOW()
    );
END$$

DELIMITER ;

-------------------------------------------------------------------------------------------------------------
--3. RegistrarHistorialDeCosto: Guarda el historial de cambios en los costos de alquiler de las películas.
-------------------------------------------------------------------------------------------------------------

DELIMITER $$

CREATE TRIGGER RegistrarHistorialDeCosto
BEFORE UPDATE ON pelicula
FOR EACH ROW
BEGIN
    -- Solo registrar si realmente cambió el rental_rate
    IF OLD.rental_rate <> NEW.rental_rate THEN
        INSERT INTO historial_costo_alquiler (
            id_pelicula,
            costo_anterior,
            costo_nuevo,
            fecha_cambio
        ) VALUES (
            OLD.id_pelicula,
            OLD.rental_rate,
            NEW.rental_rate,
            NOW()
        );
    END IF;
END$$

DELIMITER ;


---------------------------------------------------------------------------------------------------------
--4. NotificarEliminacionAlquiler: Registra una notificación cuando se elimina un registro de alquiler.
---------------------------------------------------------------------------------------------------------

DELIMITER $$

CREATE TRIGGER NotificarEliminacionAlquiler
BEFORE DELETE ON alquiler
FOR EACH ROW
BEGIN
    INSERT INTO notificaciones_eliminacion (
        id_alquiler,
        id_cliente,
        id_empleado,
        fecha_alquiler,
        fecha_devolucion,
        mensaje
    ) VALUES (
        OLD.id_alquiler,
        OLD.id_cliente,
        OLD.id_empleado,
        OLD.fecha_alquiler,
        OLD.fecha_devolucion,
        CONCAT('Alquiler eliminado. ID Cliente: ', OLD.id_cliente, ', ID Empleado: ', OLD.id_empleado)
    );
END$$

DELIMITER ;

----------------------------------------------------------------------------------------------------------------------
--5. RestringirAlquilerConSaldoPendiente: Evita que un cliente con saldo pendiente pueda realizar nuevos alquileres.
----------------------------------------------------------------------------------------------------------------------

DELIMITER $$

CREATE TRIGGER RestringirAlquilerConSaldoPendiente
BEFORE INSERT ON alquiler
FOR EACH ROW
BEGIN
    DECLARE cantidad_pendientes INT;

    SELECT 
        COUNT(*) INTO cantidad_pendientes
    FROM 
        alquiler a
    LEFT JOIN 
        pago p ON a.id_alquiler = p.id_alquiler
    WHERE 
        a.id_cliente = NEW.id_cliente
        AND p.id_pago IS NULL;

    IF cantidad_pendientes > 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'El cliente tiene alquileres sin pago. No puede realizar nuevos alquileres.';
    END IF;
END$$

DELIMITER ;
