import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:movie/provider/movie_provider.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SearchField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  const _SearchField({
    required this.label,
    required this.controller,
    required this.hint,
  });
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 10),
            ),
            const SizedBox(height: 2),
            Container(
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    isCollapsed: true,
                    hintText: hint,
                    hintStyle: const TextStyle(
                      color: Colors.white24,
                      fontSize: 12,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsPageState extends State<SettingsPage> {
  static const _syncChannel = WindowMethodChannel(
    'movie_sync_channel',
    mode: ChannelMode.unidirectional,
  );
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _onAdd() {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();
    if (name.isEmpty || url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) return;
    context.read<MovieProvider>().addResource(name, url);
    _nameController.clear();
    _urlController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MovieProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFF141414),
      appBar: AppBar(
        backgroundColor: Colors.black,
        toolbarHeight: 70,
        title: Row(
          children: [
            const SizedBox(width: 10),
            _SearchField(
              label: "资源网名称",
              controller: _nameController,
              hint: "例如：非凡资源",
            ),
            const SizedBox(width: 10),
            _SearchField(
              label: "API 链接 (JSON)",
              controller: _urlController,
              hint: "http://.../json/",
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Colors.green,
              size: 28,
            ),
            onPressed: _onAdd,
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: provider.resourceList.length,
        separatorBuilder: (context, index) =>
            const Divider(color: Colors.white10),
        itemBuilder: (context, index) {
          final item = provider.resourceList[index];
          final isActive = provider.activeUrl == item['url'];
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 5,
            ),
            title: Text(
              item['name'] ?? '',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              item['url'] ?? '',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  onPressed: isActive
                      ? null
                      : () async {
                          final targetUrl = item['url']!;
                          await provider.switchResource(targetUrl);
                          _syncChannel.invokeMethod(
                            'onResourceChanged',
                            targetUrl,
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isActive ? Colors.grey : Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(isActive ? "正在使用" : "切换使用"),
                ),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                  onPressed: () => provider.deleteResource(index),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
