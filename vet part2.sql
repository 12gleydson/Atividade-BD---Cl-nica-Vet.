 CREATE DATABASE vt;

USE vt;


CREATE TABLE Donos (
    id_dono INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(50) NOT NULL,
    telefone VARCHAR(20), 
    email VARCHAR(50)
);


CREATE TABLE Pacientes (
    id_paciente INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(45) NOT NULL,
    sobrenome VARCHAR(45) NOT NULL,
    idade INT NOT NULL, 
    especie VARCHAR(50) NOT NULL,
    id_dono INT,
    total_gasto DECIMAL(10, 2) DEFAULT 0.00 
);


ALTER TABLE Pacientes ADD FOREIGN KEY (id_dono) REFERENCES Donos(id_dono);


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
    custo DECIMAL(10, 2) NOT NULL, 
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


CREATE TABLE Agendamentos (
    id_agendamento INT PRIMARY KEY AUTO_INCREMENT,
    id_paciente INT,
    id_veterinario INT,
    data_agendamento DATE NOT NULL,
    status VARCHAR(20) NOT NULL, 
    FOREIGN KEY (id_paciente) REFERENCES Pacientes(id_paciente),
    FOREIGN KEY (id_veterinario) REFERENCES Veterinarios(id_veterinario)
);


CREATE TABLE Procedimentos (
    id_procedimento INT PRIMARY KEY AUTO_INCREMENT,
    id_consulta INT,
    tipo_procedimento VARCHAR(50) NOT NULL,
    descricao VARCHAR(100),
    FOREIGN KEY (id_consulta) REFERENCES Consultas(id_consulta)
);


INSERT INTO Donos (nome, telefone, email) VALUES
('Carlos Silva', '123456789', 'carlos@gmail.com'),
('Ana Oliveira', '987654321', 'ana@gmail.com');

INSERT INTO Pacientes (nome, sobrenome, idade, especie, id_dono) VALUES 
('Luna', 'Julia', 3, 'Cachorro', 1),
('Max', 'Silva', 5, 'Gato', 2),
('Rex', 'Ferreira', 2, 'Cachorro', NULL);

INSERT INTO Veterinarios (nome, especialidade) VALUES 
('Dr. Enrico', 'Vacinação'),
('Dra. Ana', 'Cirurgia'),
('Dr. João', 'Odontologia');

INSERT INTO Consultas (id_paciente, id_veterinario, data_consulta, custo) VALUES 
(1, 1, '2024-10-23', 25.00),
(2, 2, '2024-10-24', 50.00),
(3, 3, '2024-10-25', 75.00);

INSERT INTO Procedimentos (id_consulta, tipo_procedimento, descricao) VALUES 
(1, 'Vacinação', 'Vacinação contra raiva'),
(2, 'Cirurgia', 'Cirurgia de remoção de cisto'),
(3, 'Raio-X', 'Raio-X da perna direita');


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

CREATE PROCEDURE AtualizarPaciente(
    IN p_id_paciente INT,
    IN p_novo_nome VARCHAR(45),
    IN p_novo_sobrenome VARCHAR(45),
    IN p_nova_idade INT,
    IN p_nova_especie VARCHAR(50)
)
BEGIN
    UPDATE Pacientes
    SET nome = COALESCE(p_novo_nome, nome),
        sobrenome = COALESCE(p_novo_sobrenome, sobrenome),
        idade = COALESCE(p_nova_idade, idade),
        especie = COALESCE(p_nova_especie, especie)
    WHERE id_paciente = p_id_paciente;
END //

CREATE PROCEDURE RemoverConsulta(
    IN p_id_consulta INT
)
BEGIN
    DELETE FROM Consultas
    WHERE id_consulta = p_id_consulta;
END //


CREATE FUNCTION TotalGastoPaciente(
    p_id_paciente INT
) RETURNS DECIMAL(10, 2)
DETERMINISTIC
BEGIN
    DECLARE v_total DECIMAL(10, 2) DEFAULT 0.00;
    
    SELECT COALESCE(SUM(custo), 0.00) INTO v_total
    FROM Consultas
    WHERE id_paciente = p_id_paciente;

    RETURN v_total;
END //

CREATE TRIGGER VerificarIdadePaciente
BEFORE INSERT ON Pacientes
FOR EACH ROW
BEGIN
    IF NEW.idade <= 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Idade do paciente deve ser um número positivo.';
    END IF;
END //

CREATE TRIGGER AtualizarCustoConsulta
AFTER UPDATE ON Consultas
FOR EACH ROW
BEGIN
    IF OLD.custo <> NEW.custo THEN
        INSERT INTO Log_Consultas (id_consulta, custo_antigo, custo_novo)
        VALUES (OLD.id_consulta, OLD.custo, NEW.custo);
    END IF;
END //

CREATE TRIGGER MarcarAgendamentoFinalizado
AFTER INSERT ON Consultas
FOR EACH ROW
BEGIN
    UPDATE Agendamentos
    SET status = 'Finalizado'
    WHERE id_paciente = NEW.id_paciente
    AND id_veterinario = NEW.id_veterinario
    AND data_agendamento = NEW.data_consulta;
END //

CREATE TRIGGER VerificarFormatoTelefone
BEFORE INSERT ON Donos
FOR EACH ROW
BEGIN
    IF NEW.telefone NOT REGEXP '^[0-9]{9,20}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Formato de telefone inválido. O número deve conter apenas dígitos.';
    END IF;
END //

CREATE TRIGGER AtualizarTotalDespesasPaciente
AFTER INSERT ON Consultas
FOR EACH ROW
BEGIN
    UPDATE Pacientes
    SET total_gasto = (SELECT COALESCE(SUM(custo), 0.00)
                       FROM Consultas
                       WHERE id_paciente = NEW.id_paciente)
    WHERE id_paciente = NEW.id_paciente;
END //

DELIMITER ;


CALL AgendarConsulta(1, 1, '2024-10-01', 20.00);
CALL AtualizarPaciente(1, 'Antonia', 'Silva', 4, 'Cachorro');
CALL RemoverConsulta(1);
SELECT TotalGastoPaciente(1);
UPDATE Consultas SET custo = 30.00 WHERE id_consulta = 2;
SELECT * FROM Log_Consultas;



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

CREATE PROCEDURE AtualizarPaciente(
    IN p_id_paciente INT,
    IN p_novo_nome VARCHAR(45),
    IN p_novo_sobrenome VARCHAR(45),
    IN p_nova_idade INT,
    IN p_nova_especie VARCHAR(50)
)
BEGIN
    UPDATE Pacientes
    SET nome = COALESCE(p_novo_nome, nome),
        sobrenome = COALESCE(p_novo_sobrenome, sobrenome),
        idade = COALESCE(p_nova_idade, idade),
        especie = COALESCE(p_nova_especie, especie)
    WHERE id_paciente = p_id_paciente;
END //

CREATE PROCEDURE RemoverConsulta(
    IN p_id_consulta INT
)
BEGIN
    DELETE FROM Consultas
    WHERE id_consulta = p_id_consulta;
END //



CREATE PROCEDURE RegistrarNovoDono(
    IN p_nome VARCHAR(50),
    IN p_telefone VARCHAR(20),
    IN p_email VARCHAR(50)
)
BEGIN
    INSERT INTO Donos (nome, telefone, email)
    VALUES (p_nome, p_telefone, p_email);
END //

CREATE PROCEDURE BuscarPacientePorId(
    IN p_id_paciente INT
)
BEGIN
    SELECT * FROM Pacientes WHERE id_paciente = p_id_paciente;
END //

CREATE PROCEDURE BuscarVeterinarioPorId(
    IN p_id_veterinario INT
)
BEGIN
    SELECT * FROM Veterinarios WHERE id_veterinario = p_id_veterinario;
END //

CREATE PROCEDURE ListarConsultasPorPaciente(
    IN p_id_paciente INT
)
BEGIN
    SELECT * FROM Consultas WHERE id_paciente = p_id_paciente;
END //

CREATE PROCEDURE RemoverDono(
    IN p_id_dono INT
)
BEGIN
    DELETE FROM Donos
    WHERE id_dono = p_id_dono AND NOT EXISTS (
        SELECT 1 FROM Pacientes WHERE id_dono = p_id_dono
    );
END //

DELIMITER ;

CALL RegistrarNovoDono('Marcos Souza', '987654321', 'marcos@gmail.com');
CALL BuscarPacientePorId(1);
CALL BuscarVeterinarioPorId(1);
CALL ListarConsultasPorPaciente(1);
CALL RemoverDono(1); 