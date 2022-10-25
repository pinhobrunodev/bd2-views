create table proposta_matricula (
matricula_aluno integer not null,
cod_disciplina char(6) not null,
constraint pk_proposta_matricula
primary key (matricula_aluno, cod_disciplina));

create table aluno (
matricula serial not null,
nome_aluno varchar(40) not null,
telefone varchar(11) ,
constraint pk_aluno
primary key (matricula));

create table disciplina (
cod char(6) not null,
nome_disciplina varchar(100) not null,
carga_horaria smallint not null,
matricula_professor integer not null,
constraint pk_disciplina
primary key (cod),
constraint ck_disciplina_carga_horaria
check (carga_horaria in (30, 60, 90)));

create table professor (
matricula serial not null,
nome_professor varchar(40) not null,
data_admissao date not null,
email varchar(250) ,
constraint pk_professor
primary key (matricula));

alter table proposta_matricula
add constraint fk_proposta_matricula_aluno
foreign key (matricula_aluno)
references aluno
on delete cascade,
add constraint fk_proposta_matricula_disciplina
foreign key (cod_disciplina)
references disciplina;
alter table disciplina
add constraint fk_disciplina_professor

foreign key (matricula_professor)
references professor;



/* ########## QUESTAO 1 ########## */

/*
a) Crie uma view que consolide os dados das tabelas de aluno, disciplina e proposta
de matrícula;
*/

create view consolidarInformacoesAlunos as
select * from aluno al
INNER JOIN proposta_matricula pa on al.matricula = pa.matricula_aluno
INNER JOIN disciplina d on pa.cod_disciplina = d.cod;


/*
b) Construa uma view baseada na seguinte consulta:
Professores que não lecionam nenhuma disciplina:
■ Saída: nome e email do professor
■ Filtro: (sem filtro)
■ Ordernação: ordem crescente de nome de professor
*/

create view consolidarProfessoresNaolecionam as
select prof.email, prof.nome_professor from professor prof
where 0 = (
	SELECT 
   COUNT(*) 
FROM 
   disciplina d
WHERE
   d.matricula_professor = prof.matricula
);

/*
c) Construa uma view baseada na seguinte consulta:
Alunos que ainda não fizeram nenhuma proposta de matrícula:

■ Saída: nome e matrícula do aluno;
■ Filtro: (sem filtro)
■ Ordenação: ordem crescente de nome do aluno;
*/


create view consolidarAlunosSemPropostaMatricula as
select alun.nome_aluno, alun.matricula from aluno alun
where 0 = (
	SELECT 
   COUNT(*) 
FROM 
   proposta_matricula pm
WHERE
   pm.matricula_aluno = alun.matricula
);

/*
d)Construa uma materialized view para o item b.
Em seguida, liste todos os registros da view e insira 3 novos registros.
Liste novamente todos os registros e observe o resultado.
Atualize a materialized view e repita a listagem.
*/

CREATE MATERIALIZED VIEW consolidarProfessoresNaolecionaMaterializedView AS
select prof.email, prof.nome_professor from professor prof
where 0 = (
	SELECT 
   COUNT(*) 
FROM 
   disciplina d
WHERE
   d.matricula_professor = prof.matricula
);
CREATE UNIQUE INDEX consolidarProfessoresNaolecionaMaterializedViewIndex
ON professor (matricula);
REFRESH MATERIALIZED VIEW consolidarProfessoresNaolecionaMaterializedView;

/* 

2) 
considera a especificação das tabelas a seguir:

emprestimo = @ISBN + @data_emprestimo + matricula_leitor + data_devolucao
leitor = @matricula + nome + telefone
editora = @codigo + nome
livro = @ISBN + titulo + tipo + codigo_editora


Observações:
● Este modelo é uma simplificação da realidade, com objetivos acadêmicos,
por este motivo, existe apenas um exemplar de cada livro, motivo pelo qual
não existe a entidade exemplar e o empréstimo é feito sobre a entidade
livro;
● Um livro não pode ser emprestado mais de uma vez no mesmo dia.

*/

/*
a) Crie o script SQL de criação das tabelas. Lembre-se de realizar uma criteriosa
seleção dos datatypes, bem como de especificar corretamente as constraints.
*/


CREATE TABLE leitor (
matricula_leitor integer  NOT NULL,
nome_leitor varchar(40)  NOT NULL,
telefone_leitor varchar(40)  NOT NULL,
CONSTRAINT pk_matricula_leitor PRIMARY KEY (matricula_leitor)
);


CREATE TABLE emprestimo (
ISBN varchar(13)  NOT NULL,
data_emprestimo Date NOT NULL,
data_devolucao Date,
matricula_leitor integer,	
FOREIGN KEY (matricula_leitor) REFERENCES leitor (matricula_leitor),
CONSTRAINT pk_codigo_emprestimo_ISBN PRIMARY KEY (ISBN)
);

CREATE TABLE editora (
codigo_editora serial  NOT NULL,
nome_editora varchar(40)  NOT NULL,
CONSTRAINT pk_codigo_editora PRIMARY KEY (codigo_editora)
);


CREATE TABLE livro (
ISBN varchar(13)  NOT NULL,
titulo_livro varchar(100)  NOT NULL,
tipo_livro varchar(1)  NOT NULL,
codigo_editora integer,
FOREIGN KEY (codigo_editora) REFERENCES editora (codigo_editora),
CONSTRAINT pk_livro_ISBN PRIMARY KEY (ISBN)
);

/*
b) Crie uma view que liste os livros do tipo E (Empréstimo). Sua view deve conter:
ISBN, título do livro e nome da editora. Obs: devem ser retornados também os
livros que não tem editora conhecida.
*/

create view consolidarLivrosTipoE as
select li.titulo_livro, li.ISBN, ed.nome_editora as nome_editora 
from livro li INNER JOIN editora ed 
on ed.codigo_editora = li.codigo_editora
where li.tipo_livro = 'E';


/*
d) Construa scripts SQL que realizem a inclusão de 1 editoras, 1 livros, 1 leitor e
1 empréstimo.
*/

insert into leitor(matricula_leitor,nome_leitor,telefone_leitor) values ('1','Jose','7599999999');
insert into emprestimo(ISBN,data_emprestimo,matricula_leitor,data_devolucao) values ('1','10/05/2022','1','11/05/2022');
insert into editora(nome_editora) values ('Guilherme Pontes');
insert into livro(ISBN,titulo_livro,tipo_livro,codigo_editora) values ('1','Livro de Guizao','E',1);
insert into livro(ISBN,titulo_livro,tipo_livro,codigo_editora) values ('2','Livro de Caio','C',1);
insert into livro(ISBN,titulo_livro,tipo_livro) values ('3','Livro de Duduzera','E');



/*
e) Construa uma view que retorne os livros e suas respectivas editoras, mesmo
aqueles livros que não possuem editora cadastrada. Sua consulta deve retornar:
título do livro e nome da editora (quando disponível, quando não foi con ecida a
editora para um livro, sua consulta deve retornar para este campo o texto “(editora
desconhecida)”), ordenado por título do livro (ordem crescente);
*/
create view consolidarLivrosEditoras as
select li.titulo_livro, COALESCE(ed.nome_editora,'Editora desconhecida') AS nome_editora
from livro li LEFT JOIN editora ed 
on ed.codigo_editora = li.codigo_editora
order by li.titulo_livro asc;
