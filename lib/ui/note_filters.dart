import 'package:flutter/material.dart';

import '../state/app_controller.dart';
import 'design_system.dart';

/// Selection stays local until Apply; closing the sheet leaves Home unchanged.
class NoteLabelFilter extends StatefulWidget {
  const NoteLabelFilter({
    super.key,
    required this.controller,
    required this.selected,
  });
  final AppController controller;
  final Set<String> selected;

  @override
  State<NoteLabelFilter> createState() => _NoteLabelFilterState();
}

class _NoteLabelFilterState extends State<NoteLabelFilter> {
  late final selected = Set<String>.of(widget.selected);
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      final query = search.text.trim().toLowerCase();
      final available = c.labels.toSet();
      selected.removeWhere((id) => !available.contains(id));
      final matches = c.labels
          .where((id) => c.labelName(id).toLowerCase().contains(query))
          .toList();
      final room =
          MediaQuery.sizeOf(context).height -
          MediaQuery.viewInsetsOf(context).bottom;
      final compact =
          room < 600 || MediaQuery.textScalerOf(context).scale(1) >= 1.5;
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: (room * .85).clamp(0, 680),
            child: Padding(
              padding: EdgeInsets.all(compact ? 12 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: CustomScrollView(
                      key: const Key('label-filter-list'),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      slivers: [
                        SliverToBoxAdapter(
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: SectionHeading(
                                      'Bộ lọc nhãn',
                                      detail: compact ? null : 'Ghi chú cần có tất cả nhãn đã chọn.',
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Đóng bộ lọc',
                                    onPressed: () => Navigator.pop(context),
                                    icon: const Icon(Icons.close),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                key: const Key('label-filter-search'),
                                controller: search,
                                decoration: const InputDecoration(
                                  labelText: 'Tìm nhãn',
                                  prefixIcon: Icon(Icons.search),
                                ),
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                        if (matches.isEmpty)
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text('Không có nhãn phù hợp.'),
                            ),
                          )
                        else
                          SliverList.builder(
                            itemCount: matches.length,
                            itemBuilder: (context, index) {
                              final id = matches[index];
                              return CheckboxListTile(
                                key: ValueKey('filter-label-$id'),
                                title: Text(c.labelName(id)),
                                value: selected.contains(id),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                onChanged: (value) => setState(() {
                                  if (value == true) {
                                    selected.add(id);
                                  } else {
                                    selected.remove(id);
                                  }
                                }),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 12,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      TextButton(
                        onPressed: selected.isEmpty
                            ? null
                            : () => setState(selected.clear),
                        child: const Text('Bỏ chọn'),
                      ),
                      FilledButton(
                        key: const Key('apply-label-filter'),
                        onPressed: () =>
                            Navigator.pop(context, Set.of(selected)),
                        child: Text(
                          compact ? 'Áp dụng' : 'Áp dụng (${selected.length})',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
