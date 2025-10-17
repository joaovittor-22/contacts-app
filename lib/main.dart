import 'package:flutter/material.dart';
import 'package:contacts_app/Models/contact_model.dart';
import 'package:contacts_app/Repository/contacts_db.dart';
import 'package:contacts_app/Components/alert.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Contatos APP'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ContactRepository _repository = ContactRepository();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  var searchText = "";

  void _addContact(BuildContext context, [Contact? contact]) {
    // Preenche os campos se for edição, senão limpa
    _nameController.text = contact?.name ?? '';
    _phoneController.text = contact?.phone ?? '';
    _emailController.text = contact?.email ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              top: 32,
              left: 16,
              right: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  contact == null ? 'Cadastrar contato' : 'Editar contato',
                  style: TextStyle(fontSize: 20),
                ),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(labelText: "Nome"),
                ),
                TextField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText: "Telefone"),
                ),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: "Email"),
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_nameController.text.isEmpty ||
                        _phoneController.text.isEmpty ||
                        _emailController.text.isEmpty) {
                      showAlert(context, "Preencha todos os campos");
                      return;
                    }

                    final updatedContact = Contact(
                      id: contact?.id, // importante para update
                      name: _nameController.text,
                      phone: _phoneController.text,
                      email: _emailController.text,
                    );

                    if (contact == null) {
                      await _repository.insertContact(updatedContact);
                    } else {
                      await _repository.updateContact(updatedContact);
                    }

                    Navigator.pop(context);
                    setState(() {}); // Atualiza a lista
                  },
                  child: Text('Salvar'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: "Pesquise um contato",
              suffixIcon: Icon(Icons.search),
            ),
            onChanged: (text) {
              searchText = text;
              setState(() {});
            },
          ),
          Expanded(
            child: FutureBuilder<List<Contact>>(
              future: _repository.getAllContacts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                var contacts = snapshot.data ?? [];
                if (searchText.isNotEmpty) {
                  contacts.retainWhere(
                    (item) => item.name.toString().contains(searchText),
                  );
                }

                if (contacts.isEmpty) {
                  return Center(child: Text("Nenhum contato encontrado"));
                }

                return ListView.builder(
                  itemCount: contacts.length,
                  itemBuilder: (context, index) {
                    final contact = contacts[index];
                    return ExpansionTile(
                      title: Text(contact.name),
                      trailing: SizedBox(
                        width: 100,
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.delete),
                              onPressed: () async {
                                showAlert(
                                  context,
                                  "Tem certeza que deseja deletar este contato?",
                                  true,
                                  () async {
                                    await _repository.deleteContact(contact);
                                    setState(() {});
                                  },
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () async {
                                _addContact(context, contact);
                              },
                            ),
                          ],
                        ),
                      ),
                      expandedAlignment: Alignment.centerLeft,
                      childrenPadding: EdgeInsets.only(left: 25),
                      children: [
                        Text('Email: ${contact.email}'),
                        Text('Telefone: ${contact.phone}'),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addContact(context),
        tooltip: 'Cadastrar contato',
        child: const Icon(Icons.add),
      ),
    );
  }
}
