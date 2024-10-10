class Task {
  final int id;
  final String title;
  bool completed;

  Task({
    required this.id,
    required this.title,
    required this.completed,
  });

  // Méthode pour créer une instance de Task à partir d'un JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      completed: json['completed'],
    );
  }

  // Méthode pour convertir une instance de Task en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'completed': completed,
    };
  }
}
