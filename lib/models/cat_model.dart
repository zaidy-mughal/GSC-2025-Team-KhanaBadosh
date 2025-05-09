class Cat {
  final String id;
  final String name;
  final String breed;
  final int age;

  Cat({required this.id, required this.name, required this.breed, required this.age});

  factory Cat.fromJson(Map<String, dynamic> json) => Cat(
    id: json['id'],
    name: json['name'],
    breed: json['breed'],
    age: json['age'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'breed': breed,
    'age': age,
  };
}