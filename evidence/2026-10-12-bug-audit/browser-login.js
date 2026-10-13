async page => {
  await page.getByRole('textbox', { name: 'Email', exact: true }).fill('ui-refresh-owner@example.test');
  await page.getByRole('textbox', { name: 'Mật khẩu', exact: true }).fill('safe-password-123');
  await page.getByRole('button', { name: 'Đăng nhập', exact: true }).click();
  return { login: 'synthetic account', result: 'PASS' };
}
