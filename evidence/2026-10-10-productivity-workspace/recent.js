async page => {
  await page.getByRole('button', {name: 'Thông tin cần bảo vệ Ghi chú của bạn', exact: true}).click();
  await page.getByRole('button', {name: 'Quay lại', exact: true}).click();
  await page.getByRole('button', {name: 'Kế hoạch sáng tạo Ghi chú của bạn', exact: true}).click();
  await page.getByRole('button', {name: 'Quay lại', exact: true}).click();
  await page.getByRole('checkbox', {name: 'Gần đây', exact: true}).click();
}
