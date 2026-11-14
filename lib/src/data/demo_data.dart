import '../domain/models.dart';

const demoUser = UserProfile(
  id: 'user-demo',
  name: 'Lucas Martins',
  email: 'lucas@buillon.demo',
  avatar: 'assets/images/avatar_1.jpg',
  bio: 'Boa comida, boas histórias. Explorando os sabores de São Paulo.',
);

List<Restaurant> demoRestaurants() {
  const entries = [
    (
      id: 'r1',
      name: 'Casa do Manjericão',
      category: 'Italiana',
      neighborhood: 'Pinheiros',
      address: 'Rua dos Pinheiros, 420',
      image: 'restaurant_1',
      dish: 'Massa artesanal ao pesto',
      dishImage: 'dish_1',
      description:
          'Uma casa acolhedora onde a tradição italiana encontra ingredientes frescos. Massas feitas à mão, uma boa taça de vinho e tempo para aproveitar.',
      price: '\$\$\$',
    ),
    (
      id: 'r2',
      name: 'Quintal da Vila',
      category: 'Brasileira',
      neighborhood: 'Vila Madalena',
      address: 'Rua Harmonia, 215',
      image: 'restaurant_2',
      dish: 'Bowl de grãos e legumes',
      dishImage: 'dish_5',
      description:
          'Sabores brasileiros, ingredientes da estação e uma mesa que convida a ficar. O lugar certo para um almoço sem pressa.',
      price: '\$\$',
    ),
    (
      id: 'r3',
      name: 'Nori & Co.',
      category: 'Japonesa',
      neighborhood: 'Liberdade',
      address: 'Rua Galvão Bueno, 180',
      image: 'restaurant_3',
      dish: 'Combinado do chef',
      dishImage: 'dish_3',
      description:
          'Cortes delicados, peixes selecionados e a hospitalidade japonesa em cada detalhe. Uma experiência para todos os sentidos.',
      price: '\$\$\$',
    ),
    (
      id: 'r4',
      name: 'Forno da Esquina',
      category: 'Pizzaria',
      neighborhood: 'Moema',
      address: 'Alameda dos Arapanés, 340',
      image: 'restaurant_4',
      dish: 'Pizza da casa',
      dishImage: 'dish_4',
      description:
          'Massa de longa fermentação e forno bem quente. Pizzas para compartilhar com quem faz qualquer noite ser especial.',
      price: '\$\$',
    ),
    (
      id: 'r5',
      name: 'Brasa & Lenha',
      category: 'Brasileira',
      neighborhood: 'Itaim Bibi',
      address: 'Rua João Cachoeira, 92',
      image: 'restaurant_5',
      dish: 'Bife grelhado com legumes',
      dishImage: 'dish_brasa',
      description:
          'Cozinha de fogo, receitas afetivas e ingredientes brasileiros. Um encontro entre a brasa e a criatividade.',
      price: '\$\$\$',
    ),
    (
      id: 'r6',
      name: 'Botânica Cozinha',
      category: 'Vegetariana',
      neighborhood: 'Vila Mariana',
      address: 'Rua Joaquim Távora, 610',
      image: 'restaurant_6',
      dish: 'Bowl da estação',
      dishImage: 'dish_6',
      description:
          'Vegetais são os protagonistas de uma cozinha colorida e cheia de textura. Comida feita com cuidado, do campo à mesa.',
      price: '\$\$',
    ),
    (
      id: 'r7',
      name: 'Ponto do Burger',
      category: 'Hamburgueria',
      neighborhood: 'Perdizes',
      address: 'Rua Cardoso de Almeida, 251',
      image: 'restaurant_3',
      dish: 'Burger artesanal',
      dishImage: 'dish_2',
      description:
          'Pão macio, carne no ponto e combinações que surpreendem. Hambúrgueres artesanais em um ambiente descontraído.',
      price: '\$\$',
    ),
    (
      id: 'r8',
      name: 'Cantina da Nonna',
      category: 'Italiana',
      neighborhood: 'Bixiga',
      address: 'Rua Treze de Maio, 87',
      image: 'restaurant_5',
      dish: 'Penne cremoso da Nonna',
      dishImage: 'dish_penne',
      description:
          'Receitas de família e porções generosas em uma cantina cheia de memórias. Aqui, todo mundo se sente em casa.',
      price: '\$\$',
    ),
    (
      id: 'r9',
      name: 'Maré Alta',
      category: 'Frutos do mar',
      neighborhood: 'Jardins',
      address: 'Alameda Lorena, 730',
      image: 'restaurant_1',
      dish: 'Salmão grelhado com limão',
      dishImage: 'dish_salmao',
      description:
          'O frescor do litoral em plena cidade. Uma cozinha leve que valoriza a origem e a qualidade de cada ingrediente.',
      price: '\$\$\$',
    ),
    (
      id: 'r10',
      name: 'Pão & Prosa',
      category: 'Café',
      neighborhood: 'Santa Cecília',
      address: 'Rua Barão de Tatuí, 140',
      image: 'restaurant_2',
      dish: 'Croissant com café',
      dishImage: 'dish_croissant',
      description:
          'Café passado na hora, cozinha afetiva e boas conversas. Seu pequeno refúgio no ritmo da cidade.',
      price: '\$',
    ),
    (
      id: 'r11',
      name: 'Terraço do Sol',
      category: 'Brasileira',
      neighborhood: 'Santana',
      address: 'Rua Voluntários da Pátria, 820',
      image: 'restaurant_6',
      dish: 'Salada da horta',
      dishImage: 'dish_horta',
      description:
          'Um terraço cheio de luz para descobrir novos sabores. Cozinha brasileira com um olhar contemporâneo.',
      price: '\$\$',
    ),
    (
      id: 'r12',
      name: 'Oliva Bistrô',
      category: 'Contemporânea',
      neighborhood: 'Pompeia',
      address: 'Rua Clélia, 305',
      image: 'restaurant_4',
      dish: 'Pasta mediterrânea',
      dishImage: 'dish_mediterranea',
      description:
          'Um novo bistrô para conhecer, com pratos de inspiração mediterrânea e ingredientes sazonais.',
      price: '\$\$\$',
    ),
  ];
  return entries
      .map(
        (e) => Restaurant(
          id: e.id,
          name: e.name,
          category: e.category,
          neighborhood: e.neighborhood,
          address: '${e.address} • São Paulo, SP',
          image: 'assets/images/${e.image}.jpg',
          price: e.price,
          description: e.description,
          hours: 'Ter a dom · 12h às 23h',
          dishes: [
            Dish(
              name: e.dish,
              image: 'assets/images/${e.dishImage}.jpg',
              description: 'Ingredientes selecionados e o toque da casa.',
            ),
          ],
        ),
      )
      .toList();
}

List<Review> demoReviews() {
  const scores = [
    [5, 5, 5, 4, 5],
    [5, 5, 4, 5],
    [5, 5, 5, 5, 4, 4],
    [5, 4, 5, 4],
    [5, 5, 4],
    [5, 4, 4],
    [4, 4, 5, 4],
    [4, 4, 4],
    [4, 4, 3],
    [4, 3, 4],
    [3, 4, 3],
  ];
  const authors = [
    ('Mariana Costa', 'avatar_2'),
    ('Pedro Alves', 'avatar_3'),
    ('Camila Rocha', ''),
    ('Rafael Lima', ''),
    ('Beatriz Souza', ''),
    ('André Santos', ''),
  ];
  const comments = [
    'Uma experiência deliciosa! O prato chegou no ponto e o atendimento foi muito atencioso. Voltarei com certeza.',
    'Ambiente acolhedor e pratos muito bem preparados. Uma ótima descoberta para o fim de semana.',
    'Ingredientes frescos e muito sabor. Gostei do cuidado em cada detalhe.',
    'Boa comida e uma equipe simpática. O pedido demorou um pouco, mas valeu a visita.',
    'Entrou para a minha lista de favoritos. Recomendo conhecer com calma e aproveitar a experiência.',
    'Uma boa opção na região. Gostei do ambiente e da apresentação dos pratos.',
  ];
  final result = <Review>[];
  for (var i = 0; i < scores.length; i++) {
    for (var j = 0; j < scores[i].length; j++) {
      result.add(
        Review(
          id: 'seed-$i-$j',
          restaurantId: 'r${i + 1}',
          userId: 'seed-user-$j',
          userName: authors[j].$1,
          userAvatar: authors[j].$2.isEmpty
              ? ''
              : 'assets/images/${authors[j].$2}.jpg',
          rating: scores[i][j],
          comment: comments[j],
          createdAt: DateTime(2026, 10, 28 - i - j),
        ),
      );
    }
  }
  for (final (id, score, comment) in [
    (
      'r1',
      5,
      'A massa artesanal é incrível. Atendimento cuidadoso e um ambiente perfeito para jantar.',
    ),
    (
      'r3',
      5,
      'Peixe fresquíssimo e apresentação impecável. Quero voltar para experimentar outros pratos.',
    ),
    (
      'r2',
      4,
      'Um quintal charmoso e comida com gosto de casa. Ótima escolha para o almoço de domingo.',
    ),
  ]) {
    result.add(
      Review(
        id: 'demo-$id',
        restaurantId: id,
        userId: demoUser.id,
        userName: demoUser.name,
        userAvatar: demoUser.avatar,
        rating: score,
        comment: comment,
        createdAt: DateTime(2026, 10, 30),
      ),
    );
  }
  return result;
}
