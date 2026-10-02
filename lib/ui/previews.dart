import 'package:flutter/material.dart';

import 'design_system.dart';

/// Design fixtures only. Never mounted by the production app or sent to an API.
class DependencyPreview extends StatelessWidget {
  const DependencyPreview({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('PREVIEW · dữ liệu minh họa')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatusNotice(
            message: 'Các thành phần bên dưới chỉ minh họa thiết kế. Chưa tích hợp dịch vụ.',
          ),
          const SizedBox(height: 24),
          Text(
            'Chia sẻ ghi chú',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const TextField(
            enabled: false,
            decoration: InputDecoration(labelText: 'Email người nhận'),
          ),
          const Wrap(
            spacing: 8,
            children: [
              Chip(label: Text('Chỉ xem')),
              Chip(label: Text('Có thể chỉnh sửa')),
            ],
          ),
          const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text('Người nhận minh họa'),
            subtitle: Text('Chỉ xem · quyền do chủ sở hữu cấp'),
          ),
          const SizedBox(height: 24),
          Text(
            'Mở khóa ghi chú',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const TextField(
            enabled: false,
            obscureText: true,
            decoration: InputDecoration(labelText: 'Mật khẩu ghi chú'),
          ),
          const StatusNotice(
            message: 'Cần kết nối để kiểm tra quyền mở khóa.',
            icon: Icons.lock_outline,
          ),
          const SizedBox(height: 24),
          Text(
            'Tóm tắt / Hỏi ghi chú',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Text(
            'Phạm vi: các ghi chú được phép truy cập. Kết quả không thay nội dung gốc.',
          ),
          const StatusNotice(
            message:
                'Chưa có đủ thông tin trong ghi chú để trả lời câu hỏi này.',
          ),
          const ListTile(
            leading: Icon(Icons.description_outlined),
            title: Text('Nguồn minh họa'),
            subtitle: Text('Mở nguồn cần kiểm tra lại quyền truy cập'),
          ),
          const SizedBox(height: 24),
          Text(
            'Màu ghi chú · preview',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(label: Text('Neutral')),
              Chip(label: Text('Sage')),
              Chip(label: Text('Sand')),
              Chip(label: Text('Sky')),
              Chip(label: Text('Lilac')),
            ],
          ),
          const SizedBox(height: 24),
          Text('Tệp đính kèm', style: Theme.of(context).textTheme.titleLarge),
          const StatusNotice(
            message: 'Không tải được tệp. Kiểm tra kết nối và quyền truy cập.',
            icon: Icons.attach_file,
          ),
        ],
      ),
    ),
  );
}
