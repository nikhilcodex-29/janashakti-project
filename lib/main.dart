import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyBSkSCVmmCLWEYi8tNLHn2Ijr5wb97u4k4",
      authDomain: "janashakti-14c62.firebaseapp.com",
      projectId: "janashakti-14c62",
      storageBucket: "janashakti-14c62.firebasestorage.app",
      messagingSenderId: "213894689137",
      appId: "1:213894689137:web:228a2c65c52701aae886d0",
    ),
  );

  runApp(const MyApp());
}

////////////////////////////////////////////////////////////

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthScreen(),
    );
  }
}

////////////////////////////////////////////////////////////
// AUTH SCREEN
////////////////////////////////////////////////////////////

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool isLogin = true;

  Future<void> submit() async {
    try {
      if (isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: pass.text.trim(),
        );
      } else {
        final user = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: pass.text.trim(),
        );

        // default role user
        await FirebaseFirestore.instance
            .collection("users")
            .doc(user.user!.uid)
            .set({"role": "user"});
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("JANASHAKTI",
                style: TextStyle(fontSize: 28, color: Colors.amber)),
            const SizedBox(height: 20),
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: pass,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: submit,
              child: Text(isLogin ? "Login" : "Register"),
            ),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(isLogin ? "Create account" : "Login instead"),
            )
          ],
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
// HOME
////////////////////////////////////////////////////////////

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<bool> isAdmin() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();
    return doc.data()?["role"] == "admin";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("JANASHAKTI"),
        actions: [
          IconButton(
              onPressed: () {
                FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const AuthScreen()));
              },
              icon: const Icon(Icons.logout))
        ],
      ),
      body: Column(
        children: [
          ElevatedButton(
            child: const Text("Report Issue"),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ReportScreen()));
            },
          ),
          ElevatedButton(
            child: const Text("View Issues"),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const IssuesScreen()));
            },
          ),
          FutureBuilder(
            future: isAdmin(),
            builder: (context, snapshot) {
              if (snapshot.data == true) {
                return ElevatedButton(
                  child: const Text("Admin Panel"),
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AdminScreen()));
                  },
                );
              }
              return const SizedBox();
            },
          )
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
// REPORT ISSUE
////////////////////////////////////////////////////////////

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final title = TextEditingController();
  final location = TextEditingController();
  String category = "Water";

  void submit() async {
    await FirebaseFirestore.instance.collection("issues").add({
      "title": title.text,
      "location": location.text,
      "category": category,
      "votes": 0,
      "status": "Pending"
    });

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Report Issue")),
      body: Column(
        children: [
          TextField(controller: title, decoration: const InputDecoration(labelText: "Title")),
          TextField(controller: location, decoration: const InputDecoration(labelText: "Location")),
          DropdownButton(
            value: category,
            items: ["Water", "Road", "Electricity"]
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (v) => setState(() => category = v!),
          ),
          ElevatedButton(onPressed: submit, child: const Text("Submit"))
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
// USER VIEW
////////////////////////////////////////////////////////////

class IssuesScreen extends StatelessWidget {
  const IssuesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Issues")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("issues").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i];

              return ListTile(
                title: Text(d["title"]),
                subtitle: Text(
                    "${d["category"]} • ${d["location"]} • ${d["status"]} • Votes: ${d["votes"]}"),
                trailing: IconButton(
                  icon: const Icon(Icons.thumb_up),
                  onPressed: () {
                    d.reference.update({"votes": d["votes"] + 1});
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

////////////////////////////////////////////////////////////
// ADMIN PANEL
////////////////////////////////////////////////////////////

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection("issues").snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();

          final docs = snapshot.data!.docs;

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final d = docs[i];

              return ListTile(
                title: Text(d["title"]),
                subtitle: Text("${d["status"]}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.check),
                      onPressed: () {
                        d.reference.update({"status": "Solved"});
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        d.reference.delete();
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}