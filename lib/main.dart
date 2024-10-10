import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'task.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Application name
      title: 'Liste de Tâches',
      // Application theme data
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // A widget which will be started on application startup
      home: const MyHomePage(title: 'Liste de Tâches'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final String apiUrl = 'https://apiflutter.vercel.app/tasks';
  List<Task> tasks = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  // Méthode pour récupérer les tâches depuis le serveur
  Future<void> fetchTasks() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        List jsonResponse = json.decode(response.body);
        setState(() {
          tasks = jsonResponse.map((task) => Task.fromJson(task)).toList();
        });
      } else {
        setState(() {
          errorMessage = 'Erreur serveur : ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur réseau : $e';
      });
    } finally {
      // S'assurer que le spinner est arrêté
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Méthode pour ajouter une nouvelle tâche
  Future<void> addTask(String title) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'title': title}),
      );
      if (response.statusCode == 201) {
        await fetchTasks();
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('Erreur serveur : ${response.statusCode}')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur réseau : $e')),
      );
    }
  }

  // Méthode pour mettre à jour une tâche (marquer comme terminée)
  Future<void> updateTask(Task task) async {
    final previousStatus = task.completed;
    setState(() {
      task.completed = !task.completed;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      final response = await http.patch(
        Uri.parse('$apiUrl/${task.id}'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'completed': task.completed}),
      );
      if (response.statusCode != 200) {
        setState(() {
          task.completed = previousStatus;
        });
        messenger.showSnackBar(
          SnackBar(content: Text('Erreur serveur : ${response.statusCode}')),
        );
      }
    } catch (e) {
      setState(() {
        task.completed = previousStatus;
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur réseau : $e')),
      );
    }
  }

  // Méthode pour supprimer une tâche
  Future<void> deleteTask(int id) async {
    // Sauvegarder la tâche à supprimer en cas d'échec
    final Task taskToRemove = tasks.firstWhere((task) => task.id == id);
    setState(() {
      tasks.removeWhere((task) => task.id == id);
    });

    // Capturer le ScaffoldMessenger avant l'appel asynchrone
    final messenger = ScaffoldMessenger.of(context);

    try {
      final response = await http.delete(Uri.parse('$apiUrl/$id'));
      if (response.statusCode != 204) {
        // Réinsérer la tâche si l'appel échoue
        setState(() {
          tasks.add(taskToRemove);
        });
        messenger.showSnackBar(
          SnackBar(content: Text('Erreur serveur : ${response.statusCode}')),
        );
      }
    } catch (e) {
      // Réinsérer la tâche en cas d'erreur réseau
      setState(() {
        tasks.add(taskToRemove);
      });
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur réseau : $e')),
      );
    }
  }

  // Boîte de dialogue pour ajouter une nouvelle tâche
  Future<void> _displayAddTaskDialog() async {
    String newTaskTitle = '';
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nouvelle Tâche'),
          content: TextField(
            onChanged: (value) {
              newTaskTitle = value;
            },
            decoration:
                const InputDecoration(hintText: "Entrez le titre de la tâche"),
          ),
          actions: [
            TextButton(
              child: const Text('Annuler'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Ajouter'),
              onPressed: () {
                Navigator.of(context).pop();
                if (newTaskTitle.isNotEmpty) {
                  addTask(newTaskTitle);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text(errorMessage!))
              : RefreshIndicator(
                  onRefresh: fetchTasks,
                  child: ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return ListTile(
                        title: Text(
                          task.title,
                          style: TextStyle(
                            decoration: task.completed
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        leading: Checkbox(
                          value: task.completed,
                          onChanged: (bool? value) {
                            updateTask(task);
                          },
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () {
                            deleteTask(task.id);
                          },
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _displayAddTaskDialog();
        },
        tooltip: 'Ajouter une tâche',
        child: const Icon(Icons.add),
      ),
    );
  }
}
