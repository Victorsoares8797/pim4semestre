-- Publica os restaurantes fictícios já incluídos na demonstração Flutter.
begin;

alter table buillon.estabelecimento
    add column if not exists chave_exemplo text,
    add column if not exists faixa_preco text,
    add column if not exists horario text;

-- Os exemplos não têm CNPJ. CNPJs preenchidos continuam únicos.
alter table buillon.estabelecimento drop constraint if exists estabelecimento_cnpj_key;
create unique index if not exists estabelecimento_cnpj_informado on buillon.estabelecimento (cnpj);
create unique index if not exists estabelecimento_chave_exemplo on buillon.estabelecimento (chave_exemplo);

-- Os pratos de exemplo não têm preço individual. A API exige preço dos novos pratos cadastrados pelo painel.
alter table buillon.buillon_app_cardapio alter column preco drop not null;

create temporary table catalogo_exemplo (
    chave text primary key,
    nome text not null,
    categoria text not null,
    bairro text not null,
    rua text not null,
    numero text not null,
    capa text not null,
    prato text not null,
    foto_prato text not null,
    descricao text not null,
    faixa_preco text not null
) on commit drop;

insert into catalogo_exemplo values
    ('r1', 'Casa do Manjericão', 'Italiana', 'Pinheiros', 'Rua dos Pinheiros', '420', 'assets/images/restaurant_1.jpg', 'Massa artesanal ao pesto', 'assets/images/dish_1.jpg', 'Uma casa acolhedora onde a tradição italiana encontra ingredientes frescos. Massas feitas à mão, uma boa taça de vinho e tempo para aproveitar.', '$$$'),
    ('r2', 'Quintal da Vila', 'Brasileira', 'Vila Madalena', 'Rua Harmonia', '215', 'assets/images/restaurant_2.jpg', 'Bowl de grãos e legumes', 'assets/images/dish_5.jpg', 'Sabores brasileiros, ingredientes da estação e uma mesa que convida a ficar. O lugar certo para um almoço sem pressa.', '$$'),
    ('r3', 'Nori & Co.', 'Japonesa', 'Liberdade', 'Rua Galvão Bueno', '180', 'assets/images/restaurant_3.jpg', 'Combinado do chef', 'assets/images/dish_3.jpg', 'Cortes delicados, peixes selecionados e a hospitalidade japonesa em cada detalhe. Uma experiência para todos os sentidos.', '$$$'),
    ('r4', 'Forno da Esquina', 'Pizzaria', 'Moema', 'Alameda dos Arapanés', '340', 'assets/images/restaurant_4.jpg', 'Pizza da casa', 'assets/images/dish_4.jpg', 'Massa de longa fermentação e forno bem quente. Pizzas para compartilhar com quem faz qualquer noite ser especial.', '$$'),
    ('r5', 'Brasa & Lenha', 'Brasileira', 'Itaim Bibi', 'Rua João Cachoeira', '92', 'assets/images/restaurant_5.jpg', 'Bife grelhado com legumes', 'assets/images/dish_brasa.jpg', 'Cozinha de fogo, receitas afetivas e ingredientes brasileiros. Um encontro entre a brasa e a criatividade.', '$$$'),
    ('r6', 'Botânica Cozinha', 'Vegetariana', 'Vila Mariana', 'Rua Joaquim Távora', '610', 'assets/images/restaurant_6.jpg', 'Bowl da estação', 'assets/images/dish_6.jpg', 'Vegetais são os protagonistas de uma cozinha colorida e cheia de textura. Comida feita com cuidado, do campo à mesa.', '$$'),
    ('r7', 'Ponto do Burger', 'Hamburgueria', 'Perdizes', 'Rua Cardoso de Almeida', '251', 'assets/images/restaurant_3.jpg', 'Burger artesanal', 'assets/images/dish_2.jpg', 'Pão macio, carne no ponto e combinações que surpreendem. Hambúrgueres artesanais em um ambiente descontraído.', '$$'),
    ('r8', 'Cantina da Nonna', 'Italiana', 'Bixiga', 'Rua Treze de Maio', '87', 'assets/images/restaurant_5.jpg', 'Penne cremoso da Nonna', 'assets/images/dish_penne.jpg', 'Receitas de família e porções generosas em uma cantina cheia de memórias. Aqui, todo mundo se sente em casa.', '$$'),
    ('r9', 'Maré Alta', 'Frutos do mar', 'Jardins', 'Alameda Lorena', '730', 'assets/images/restaurant_1.jpg', 'Salmão grelhado com limão', 'assets/images/dish_salmao.jpg', 'O frescor do litoral em plena cidade. Uma cozinha leve que valoriza a origem e a qualidade de cada ingrediente.', '$$$'),
    ('r10', 'Pão & Prosa', 'Café', 'Santa Cecília', 'Rua Barão de Tatuí', '140', 'assets/images/restaurant_2.jpg', 'Croissant com café', 'assets/images/dish_croissant.jpg', 'Café passado na hora, cozinha afetiva e boas conversas. Seu pequeno refúgio no ritmo da cidade.', '$'),
    ('r11', 'Terraço do Sol', 'Brasileira', 'Santana', 'Rua Voluntários da Pátria', '820', 'assets/images/restaurant_6.jpg', 'Salada da horta', 'assets/images/dish_horta.jpg', 'Um terraço cheio de luz para descobrir novos sabores. Cozinha brasileira com um olhar contemporâneo.', '$$'),
    ('r12', 'Oliva Bistrô', 'Contemporânea', 'Pompeia', 'Rua Clélia', '305', 'assets/images/restaurant_4.jpg', 'Pasta mediterrânea', 'assets/images/dish_mediterranea.jpg', 'Um novo bistrô para conhecer, com pratos de inspiração mediterrânea e ingredientes sazonais.', '$$$');

insert into buillon.categoria (nome_categoria)
select distinct dados.categoria
from catalogo_exemplo dados
where not exists (
    select 1 from buillon.categoria c where lower(btrim(c.nome_categoria)) = lower(dados.categoria)
);

-- Fornecedor interno, sem e-mail ou senha, para os exemplos ficarem fora dos painéis dos usuários.
insert into buillon.fornecedor (nome_responsavel, documento)
values ('Catálogo de exemplo Buillon', 'catalogo-buillon')
on conflict (documento) do nothing;

insert into buillon.estabelecimento
    (id_fornecedor, id_categoria, nome_fantasia, descricao, chave_exemplo, faixa_preco, horario, status)
select f.id_fornecedor, c.id_categoria, dados.nome, dados.descricao, dados.chave,
    dados.faixa_preco, 'Ter a dom · 12h às 23h', 'Ativo'
from catalogo_exemplo dados
join buillon.fornecedor f on f.documento = 'catalogo-buillon' and f.email is null and f.senha is null
join lateral (
    select id_categoria from buillon.categoria
    where lower(btrim(nome_categoria)) = lower(dados.categoria)
    order by id_categoria limit 1
) c on true
order by substring(dados.chave from 2)::int
on conflict (chave_exemplo) do nothing;

insert into buillon.endereco (id_estabelecimento, rua, numero, bairro, cidade, estado)
select e.id_estabelecimento, dados.rua, dados.numero, dados.bairro, 'São Paulo', 'SP'
from catalogo_exemplo dados
join buillon.estabelecimento e on e.chave_exemplo = dados.chave
where not exists (
    select 1 from buillon.endereco a where a.id_estabelecimento = e.id_estabelecimento
);

insert into buillon.buillon_app_foto (id_estabelecimento, url, legenda)
select e.id_estabelecimento, dados.capa, ''
from catalogo_exemplo dados
join buillon.estabelecimento e on e.chave_exemplo = dados.chave
where not exists (
    select 1 from buillon.buillon_app_foto f where f.id_estabelecimento = e.id_estabelecimento and f.url = dados.capa
);

insert into buillon.buillon_app_cardapio (id_estabelecimento, nome, descricao, imagem)
select e.id_estabelecimento, dados.prato, 'Ingredientes selecionados e o toque da casa.', dados.foto_prato
from catalogo_exemplo dados
join buillon.estabelecimento e on e.chave_exemplo = dados.chave
where not exists (
    select 1 from buillon.buillon_app_cardapio p
    where p.id_estabelecimento = e.id_estabelecimento and p.imagem = dados.foto_prato
);

commit;
