create table buillon.fornecedor_perfil (
    id_fornecedor integer primary key references buillon.fornecedor on delete cascade,
    bio varchar(160) not null,
    avatar varchar(255) not null
);

create table buillon.fornecedor_favorito (
    id_fornecedor integer references buillon.fornecedor on delete cascade,
    id_estabelecimento integer references buillon.estabelecimento on delete cascade,
    primary key (id_fornecedor, id_estabelecimento)
);

create index fornecedor_favorito_estabelecimento on buillon.fornecedor_favorito (id_estabelecimento);
revoke all on buillon.fornecedor_perfil, buillon.fornecedor_favorito from public;
