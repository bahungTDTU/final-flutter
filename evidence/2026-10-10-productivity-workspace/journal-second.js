async page => {
  await page.getByRole('button', {name: 'Quay lại', exact: true}).click();
  await page.getByRole('button', {name: 'Nhật ký hôm nay', exact: true}).click();
  await page.keyboard.press('Control+s');
  await page.getByRole('button', {name: 'Quay lại', exact: true}).click();
  await page.getByRole('checkbox', {name: 'Nhập / xuất', exact: true}).click();
}
