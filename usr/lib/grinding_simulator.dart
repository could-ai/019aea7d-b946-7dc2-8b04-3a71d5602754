import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// --- Models ---

enum Rarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

class LootItem {
  final String name;
  final Rarity rarity;
  final Color color;
  final IconData icon;

  LootItem({
    required this.name,
    required this.rarity,
    required this.color,
    required this.icon,
  });
}

// --- Logic ---

class GameLogic {
  static final Random _random = Random();

  static LootItem generateLoot() {
    double roll = _random.nextDouble(); // 0.0 to 1.0

    if (roll < 0.01) { // 1%
      return LootItem(name: "Ancient Dragon Sword", rarity: Rarity.legendary, color: Colors.orange, icon: Icons.auto_awesome);
    } else if (roll < 0.05) { // 4%
      return LootItem(name: "Void Armor", rarity: Rarity.epic, color: Colors.purpleAccent, icon: Icons.shield);
    } else if (roll < 0.15) { // 10%
      return LootItem(name: "Golden Ring", rarity: Rarity.rare, color: Colors.blue, icon: Icons.diamond);
    } else if (roll < 0.40) { // 25%
      return LootItem(name: "Iron Dagger", rarity: Rarity.uncommon, color: Colors.green, icon: Icons.hardware);
    } else { // 60%
      return LootItem(name: "Broken Rock", rarity: Rarity.common, color: Colors.grey, icon: Icons.terrain);
    }
  }
}

// --- UI ---

class GrindingSimulator extends StatefulWidget {
  const GrindingSimulator({super.key});

  @override
  State<GrindingSimulator> createState() => _GrindingSimulatorState();
}

class _GrindingSimulatorState extends State<GrindingSimulator> {
  // State
  LootItem? _currentLoot;
  List<LootItem> _inventory = [];
  int _attempts = 0;
  bool _isAutoGrinding = false;
  Timer? _grindTimer;
  
  // Settings
  Rarity _targetRarity = Rarity.legendary;
  double _speed = 1.0; // Actions per second (approx)

  @override
  void dispose() {
    _grindTimer?.cancel();
    super.dispose();
  }

  void _performAction() {
    setState(() {
      _attempts++;
      _currentLoot = GameLogic.generateLoot();
      if (_currentLoot != null) {
        // Keep only last 50 items to prevent memory issues in this demo
        if (_inventory.length > 50) _inventory.removeAt(0);
        _inventory.add(_currentLoot!);
      }
    });

    _checkStopCondition();
  }

  void _checkStopCondition() {
    if (_isAutoGrinding && _currentLoot != null) {
      if (_currentLoot!.rarity == _targetRarity || 
          _currentLoot!.rarity.index > _targetRarity.index) {
        // Found target or better!
        _stopGrinding();
        _showSuccessDialog();
      }
    }
  }

  void _toggleGrinding() {
    if (_isAutoGrinding) {
      _stopGrinding();
    } else {
      _startGrinding();
    }
  }

  void _startGrinding() {
    setState(() {
      _isAutoGrinding = true;
    });
    
    // Convert speed (actions/sec) to duration
    int milliseconds = (1000 / _speed).round();
    if (milliseconds < 50) milliseconds = 50; // Cap max speed

    _grindTimer = Timer.periodic(Duration(milliseconds: milliseconds), (timer) {
      _performAction();
    });
  }

  void _stopGrinding() {
    _grindTimer?.cancel();
    setState(() {
      _isAutoGrinding = false;
    });
  }

  void _resetStats() {
    _stopGrinding();
    setState(() {
      _attempts = 0;
      _inventory.clear();
      _currentLoot = null;
    });
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Target Acquired!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_currentLoot!.icon, size: 64, color: _currentLoot!.color),
            const SizedBox(height: 16),
            Text("Found: ${_currentLoot!.name}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Rarity: ${_currentLoot!.rarity.name.toUpperCase()}", style: TextStyle(color: _currentLoot!.color)),
            const SizedBox(height: 8),
            Text("Total Attempts: $_attempts"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Awesome"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Auto Grind Simulator"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetStats,
            tooltip: "Reset",
          )
        ],
      ),
      body: Column(
        children: [
          // --- Game View Area ---
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white10),
              ),
              child: Center(
                child: _currentLoot == null
                    ? const Text("Press 'Grind' to start looting", style: TextStyle(color: Colors.grey))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TweenAnimationBuilder(
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 300),
                            builder: (context, value, child) {
                              return Transform.scale(
                                scale: value,
                                child: Icon(
                                  _currentLoot!.icon,
                                  size: 100,
                                  color: _currentLoot!.color,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _currentLoot!.name,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _currentLoot!.color,
                              shadows: [
                                Shadow(blurRadius: 10, color: _currentLoot!.color.withOpacity(0.5))
                              ],
                            ),
                          ),
                          Text(
                            _currentLoot!.rarity.name.toUpperCase(),
                            style: const TextStyle(letterSpacing: 2, fontSize: 12),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          // --- Stats Area ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatCard("Attempts", "$_attempts"),
                _buildStatCard("Inventory", "${_inventory.length}"),
                _buildStatCard("Last Rarity", _currentLoot?.rarity.name.toUpperCase() ?? "-"),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // --- Control Panel ---
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Automation Settings", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                
                // Target Selector
                Row(
                  children: [
                    const Text("Stop at: "),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButton<Rarity>(
                        value: _targetRarity,
                        isExpanded: true,
                        items: Rarity.values.map((r) {
                          Color color;
                          switch(r) {
                            case Rarity.legendary: color = Colors.orange; break;
                            case Rarity.epic: color = Colors.purpleAccent; break;
                            case Rarity.rare: color = Colors.blue; break;
                            case Rarity.uncommon: color = Colors.green; break;
                            default: color = Colors.grey;
                          }
                          return DropdownMenuItem(
                            value: r,
                            child: Text(r.name.toUpperCase(), style: TextStyle(color: color)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _targetRarity = value);
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Speed Slider
                Row(
                  children: [
                    const Text("Speed: "),
                    Expanded(
                      child: Slider(
                        value: _speed,
                        min: 1.0,
                        max: 20.0,
                        divisions: 19,
                        label: "${_speed.toInt()} x/sec",
                        onChanged: _isAutoGrinding ? null : (value) => setState(() => _speed = value),
                      ),
                    ),
                    Text("${_speed.toInt()} /s"),
                  ],
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isAutoGrinding ? null : _performAction,
                        icon: const Icon(Icons.touch_app),
                        label: const Text("Manual Click"),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _toggleGrinding,
                        icon: Icon(_isAutoGrinding ? Icons.stop : Icons.play_arrow),
                        label: Text(_isAutoGrinding ? "STOP" : "AUTO GRIND"),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: _isAutoGrinding ? Colors.redAccent : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
