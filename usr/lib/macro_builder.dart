import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- Models ---

enum ActionType { keyPress, delay, waitForImage }

class MacroStep {
  final String id;
  ActionType type;
  String? key; // For keyPress
  int? durationMs; // For delay
  String? imageName; // For waitForImage

  MacroStep({
    required this.id,
    required this.type,
    this.key,
    this.durationMs,
    this.imageName,
  });
}

// --- Logic ---

class ScriptGenerator {
  static String generatePython(List<MacroStep> steps) {
    StringBuffer buffer = StringBuffer();
    buffer.writeln("import pyautogui");
    buffer.writeln("import time");
    buffer.writeln("import keyboard  # pip install keyboard");
    buffer.writeln("");
    buffer.writeln("# --- Configuration ---");
    buffer.writeln("pyautogui.FAILSAFE = True");
    buffer.writeln("");
    buffer.writeln("print('Script starting in 5 seconds... Switch to your game window!')");
    buffer.writeln("time.sleep(5)");
    buffer.writeln("");
    buffer.writeln("print('Running... Press Ctrl+C to stop in terminal, or slam mouse to corner (Failsafe)')");
    buffer.writeln("try:");
    buffer.writeln("    while True:");
    buffer.writeln("        if keyboard.is_pressed('q'):  # Safety kill switch");
    buffer.writeln("            print('Stopping script...')");
    buffer.writeln("            break");
    buffer.writeln("");

    for (var step in steps) {
      switch (step.type) {
        case ActionType.keyPress:
          buffer.writeln("        # Press ${step.key}");
          buffer.writeln("        pyautogui.press('${step.key}')");
          break;
        case ActionType.delay:
          buffer.writeln("        # Wait ${step.durationMs}ms");
          buffer.writeln("        time.sleep(${step.durationMs! / 1000})");
          break;
        case ActionType.waitForImage:
          buffer.writeln("        # Wait for image: ${step.imageName}");
          buffer.writeln("        # Ensure '${step.imageName}' is in the same folder as this script");
          buffer.writeln("        found = None");
          buffer.writeln("        while found is None:");
          buffer.writeln("            found = pyautogui.locateOnScreen('${step.imageName}', confidence=0.8)");
          buffer.writeln("            if keyboard.is_pressed('q'): break");
          buffer.writeln("            time.sleep(0.5)");
          break;
      }
    }
    
    buffer.writeln("");
    buffer.writeln("except KeyboardInterrupt:");
    buffer.writeln("    print('Script stopped by user')");

    return buffer.toString();
  }
}

// --- UI ---

class MacroBuilder extends StatefulWidget {
  const MacroBuilder({super.key});

  @override
  State<MacroBuilder> createState() => _MacroBuilderState();
}

class _MacroBuilderState extends State<MacroBuilder> {
  final List<MacroStep> _steps = [];
  final ScrollController _scrollController = ScrollController();

  void _addStep(ActionType type) {
    setState(() {
      switch (type) {
        case ActionType.keyPress:
          _steps.add(MacroStep(
            id: DateTime.now().toString(),
            type: ActionType.keyPress,
            key: 'enter',
          ));
          break;
        case ActionType.delay:
          _steps.add(MacroStep(
            id: DateTime.now().toString(),
            type: ActionType.delay,
            durationMs: 1000,
          ));
          break;
        case ActionType.waitForImage:
          _steps.add(MacroStep(
            id: DateTime.now().toString(),
            type: ActionType.waitForImage,
            imageName: 'target.png',
          ));
          break;
      }
    });
    
    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _removeStep(int index) {
    setState(() {
      _steps.removeAt(index);
    });
  }

  void _showScriptDialog() {
    final script = ScriptGenerator.generatePython(_steps);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Generated Python Script", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                "Copy this code into a file named 'bot.py' and run it with Python.\n"
                "Requires: pip install pyautogui keyboard opencv-python",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      script,
                      style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 13),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: script));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Script copied to clipboard!")),
                    );
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text("Copy to Clipboard"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Macro Script Builder"),
        actions: [
          TextButton.icon(
            onPressed: _steps.isEmpty ? null : _showScriptDialog,
            icon: const Icon(Icons.code),
            label: const Text("Generate Script"),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Row(
        children: [
          // --- Sidebar (Tools) ---
          Container(
            width: 250,
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Add Actions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 16),
                _buildAddButton("Key Press", Icons.keyboard, ActionType.keyPress, Colors.blue),
                const SizedBox(height: 8),
                _buildAddButton("Wait / Delay", Icons.timer, ActionType.delay, Colors.orange),
                const SizedBox(height: 8),
                _buildAddButton("Wait for Image", Icons.image_search, ActionType.waitForImage, Colors.purple),
                const Spacer(),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Tip: Use 'Wait for Image' to detect game state changes (like 'Battle End' screen).",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
          
          // --- Main Content (Timeline) ---
          Expanded(
            child: Container(
              color: Colors.black12,
              child: _steps.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_fix_high, size: 64, color: Colors.white24),
                          const SizedBox(height: 16),
                          const Text("No actions added yet.", style: TextStyle(color: Colors.grey)),
                          const Text("Add actions from the left menu to build your bot.", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      scrollController: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _steps.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (oldIndex < newIndex) newIndex -= 1;
                          final item = _steps.removeAt(oldIndex);
                          _steps.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final step = _steps[index];
                        return _buildStepCard(step, index);
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(String label, IconData icon, ActionType type, Color color) {
    return ElevatedButton.icon(
      onPressed: () => _addStep(type),
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: color,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        elevation: 0,
        side: BorderSide(color: Colors.white10),
      ),
    );
  }

  Widget _buildStepCard(MacroStep step, int index) {
    return Card(
      key: ValueKey(step.id),
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.drag_handle, color: Colors.grey),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getColorForType(step.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_getIconForType(step.type), color: _getColorForType(step.type)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStepContent(step),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () => _removeStep(index),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForType(ActionType type) {
    switch (type) {
      case ActionType.keyPress: return Colors.blue;
      case ActionType.delay: return Colors.orange;
      case ActionType.waitForImage: return Colors.purple;
    }
  }

  IconData _getIconForType(ActionType type) {
    switch (type) {
      case ActionType.keyPress: return Icons.keyboard;
      case ActionType.delay: return Icons.timer;
      case ActionType.waitForImage: return Icons.image;
    }
  }

  Widget _buildStepContent(MacroStep step) {
    switch (step.type) {
      case ActionType.keyPress:
        return Row(
          children: [
            const Text("Press Key: "),
            const SizedBox(width: 8),
            DropdownButton<String>(
              value: ['enter', 'space', 'esc', 'z', 'c', 'e', 'up', 'down', 'left', 'right'].contains(step.key) ? step.key : 'enter',
              underline: Container(height: 1, color: Colors.blue),
              items: ['enter', 'space', 'esc', 'z', 'c', 'e', 'up', 'down', 'left', 'right']
                  .map((k) => DropdownMenuItem(value: k, child: Text(k.toUpperCase())))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => step.key = val);
              },
            ),
          ],
        );
      case ActionType.delay:
        return Row(
          children: [
            const Text("Wait: "),
            Expanded(
              child: Slider(
                value: step.durationMs!.toDouble(),
                min: 100,
                max: 5000,
                divisions: 49,
                label: "${step.durationMs} ms",
                onChanged: (val) => setState(() => step.durationMs = val.toInt()),
              ),
            ),
            Text("${step.durationMs} ms", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        );
      case ActionType.waitForImage:
        return Row(
          children: [
            const Text("Wait until screen shows: "),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: TextEditingController(text: step.imageName),
                decoration: const InputDecoration(
                  hintText: "filename.png",
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => step.imageName = val,
              ),
            ),
          ],
        );
    }
  }
}
