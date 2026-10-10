async page => {
  await page.getByRole('textbox', { name: 'Nội dung khởi đầu (Markdown)', exact: true }).fill('## Mục tiêu\nThảo luận ý tưởng mới.\n\n## Việc cần làm\n- [ ] Chuẩn bị bản demo\n- [ ] Ghi lại quyết định');
  await page.getByRole('button', {name: 'Lưu mẫu', exact: true}).click();
}
