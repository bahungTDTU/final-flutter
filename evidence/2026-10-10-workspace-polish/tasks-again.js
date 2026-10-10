async page => {
  await page.getByRole('checkbox',{name:'Công việc',exact:true}).click();
  await page.getByText('1/3 hoàn thành · 3 kết quả',{exact:true}).waitFor();
  await page.getByRole('checkbox',{name:'Thiết kế không gian làm việc',exact:true}).click();
  await page.getByText('2/3 hoàn thành · 3 kết quả',{exact:true}).waitFor();
  return {finalFixtureTaskToggle:true};
}
