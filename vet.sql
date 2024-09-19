CREATE DATABASE vt;
 
USE vt;
 
 
CREATE TABLE Pacientes (
    id_paciente INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(45) NOT NULL,
    sobrenome VARCHAR(45) NOT NULL,
    idade INT NOT NULL CHECK (idade > 0), -- VerificaÃ§Ã£o para idade positiva
    especie VARCHAR(50) NOT NULL
);
 
 
CREATE TABLE Veterinarios (
    id_veterinario INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(50) NOT NULL,
    especialidade VARCHAR(50) NOT NULL
);
 
 
CREATE TABLE Consultas (
    id_consulta INT PRIMARY KEY AUTO_INCREMENT,
    id_paciente INT,
    id_veterinario INT,
    data_consulta DATE NOT NULL,
    custo DECIMAL(10, 2) NOT NULL CHECK (custo >= 0), -- VerificaÃ§Ã£o para custo nÃ£o negativo
    FOREIGN KEY (id_paciente) REFERENCES Pacientes(id_paciente),
    FOREIGN KEY (id_veterinario) REFERENCES Veterinarios(id_veterinario)
);
 
CREATE TABLE Log_Consultas (
    id_log INT PRIMARY KEY AUTO_INCREMENT,
    id_consulta INT,
    custo_antigo DECIMAL(10, 2),
    custo_novo DECIMAL(10, 2),
    FOREIGN KEY (id_consulta) REFERENCES Consultas(id_consulta)
);
 
 
INSERT INTO Pacientes (nome, sobrenome, idade, especie) VALUES
('Luna', 'Julia', 3, 'Cachorro'),
('Max', 'Silva', 5, 'Gato'),
('Rex', 'Ferreira', 2, 'Cachorro');
 
INSERT INTO Veterinarios (nome, especialidade) VALUES
('Dr. Enrico', 'VacinaÃ§Ã£o'),
('Dra. Ana', 'Cirurgia'),
('Dr. JoÃ£o', 'Odontologia');
 
INSERT INTO Consultas (id_paciente, id_veterinario, data_consulta, custo) VALUES
(1, 1, '2024-10-23', 25.00),
(2, 2, '2024-10-24', 50.00),
(3, 3, '2024-10-25', 75.00);
 
 
DELIMITER //
 
CREATE PROCEDURE AgendarConsulta(
    IN p_id_paciente INT,
    IN p_id_veterinario INT,
    IN p_data_consulta DATE,
    IN p_custo DECIMAL(10, 2)
)
BEGIN
    INSERT INTO Consultas (id_paciente, id_veterinario, data_consulta, custo)
    VALUES (p_id_paciente, p_id_veterinario, p_data_consulta, p_custo);
END //
 
DELIMITER ;
 
CALL AgendarConsulta(1, 1, '2024-10-01', 20.00);
 
 
DELIMITER //
 
CREATE PROCEDURE AtualizarPaciente(
    IN p_id_paciente INT,
    IN p_novo_nome VARCHAR(45),
    IN p_novo_sobrenome VARCHAR(45),
    IN p_nova_idade INT,
    IN p_nova_especie VARCHAR(50)
)
BEGIN
    UPDATE Pacientes
    SET nome = p_novo_nome,
        sobrenome = p_novo_sobrenome,
        idade = p_nova_idade,
        especie = p_nova_especie
    WHERE id_paciente = p_id_paciente;
END //
 
DELIMITER ;
 
CALL AtualizarPaciente(1, 'Antonia', 'Silva', 4, 'Cachorro');
 
 
DELIMITER //
 
CREATE PROCEDURE RemoverConsulta(
    IN p_id_consulta INT
)
BEGIN
    DELETE FROM Consultas
    WHERE id_consulta = p_id_consulta;
END //
 
DELIMITER ;
 
CALL RemoverConsulta(1);
 
 
DELIMITER //
CREATE TABLE Log_Consultas (
    id_log INT PRIMARY KEY AUTO_INCREMENT,
    id_consulta INT,
    custo_antigo DECIMAL(10, 2),
    custo_novo DECIMAL(10, 2),
    FOREIGN KEY (id_consulta) REFERENCES Consultas(id_consulta)
 
DELIMITER ;
 
DELIMITER //
 
CREATE FUNCTION TotalGastoPaciente(
    p_id_paciente INT
) RETURNS DECIMAL(10, 2)
DETERMINISTIC
BEGIN
    DECLARE v_total DECIMAL(10, 2) DEFAULT 0.00;
    
    -- Calcula o total dos custos das consultas para o paciente
    SELECT COALESCE(SUM(custo), 0.00) INTO v_total
    FROM Consultas
    WHERE id_paciente = p_id_paciente;
 
    RETURN v_total;  -- Retorna o total calculado
END //
 
DELIMITER ;
 
 
SELECT TotalGastoPaciente(1);
 
 
DELIMITER //
 
CREATE TRIGGER VerificarIdadePaciente
BEFORE INSERT ON Pacientes
FOR EACH ROW
BEGIN
    IF NEW.idade <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Idade do paciente deve ser um nÃºmero positivo.';
    END IF;
END //
 
DELIMITER ;
 
INSERT INTO Pacientes (nome, sobrenome, idade, especie) VALUES
('Bobby', 'Bilbo', '-6','cachorro');
 
 
CREATE TABLE Log_Consultas (
    id_log INT PRIMARY KEY AUTO_INCREMENT,
    id_consulta INT,
    custo_antigo DECIMAL(10, 2),
    custo_novo DECIMAL(10, 2),
    FOREIGN KEY (id_consulta) REFERENCES Consultas(id_consulta)
);
 
DELIMITER //
 
CREATE TRIGGER AtualizarCustoConsulta
AFTER UPDATE ON Consultas
FOR EACH ROW
BEGIN
    IF OLD.custo <> NEW.custo THEN
        INSERT INTO Log_Consultas (id_consulta, custo_antigo, custo_novo)
        VALUES (OLD.id_consulta, OLD.custo, NEW.custo);
    END IF;
END //
 
DELIMITER ;
 
 
UPDATE Consultas
SET custo = 30.00
WHERE id_consulta = 2;
 
 
SELECT * FROM Log_Consultas;
 
DROP DATABASE vt;