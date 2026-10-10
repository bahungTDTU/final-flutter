async page => {
  await page.getByRole('checkbox',{name:'Thiết kế không gian làm việc',exact:true}).click();
  await page.getByText('2/3 hoàn thành · 1 kết quả',{exact:true}).waitFor();
  await page.getByRole('checkbox',{name:'Tất cả trạng thái',exact:true}).click();
  await page.getByRole('checkbox',{name:'Của bạn',exact:true}).click();
  await page.getByRole('textbox',{name:'Tìm công việc hoặc tên ghi chú',exact:true}).click();
  await page.keyboard.type('kiểm tra');
  await page.getByText('0/1 hoàn thành · 1 kết quả',{exact:true}).waitFor();
  await page.waitForTimeout(700);
  await page.screenshot({path:'D:/flutter cuoi ki/evidence/2026-10-10-workspace-polish/02-tasks-filter-desktop.png'});
  await page.getByRole('checkbox',{name:'Được chia sẻ',exact:true}).click();
  await page.getByText('0/0 hoàn thành · 0 kết quả',{exact:true}).waitFor();
  await page.getByRole('button',{name:'Xóa tìm công việc',exact:true}).click();
  await page.getByRole('checkbox',{name:'Mọi nguồn',exact:true}).click();
  await page.getByText('2/3 hoàn thành · 3 kết quả',{exact:true}).waitFor();
  await page.waitForTimeout(700);
  await page.screenshot({path:'D:/flutter cuoi ki/evidence/2026-10-10-workspace-polish/03-tasks-all-desktop.png'});
  return {toggle:true,search:true,sourceScope:true,progress:true,hiddenLocked:true};
}
