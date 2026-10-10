async page => {
  const name=page.getByRole('textbox',{name:'Tên bộ sưu tập',exact:true});
  await name.click(); await page.keyboard.press('Control+A'); await page.keyboard.type('Kế hoạch tuần');
  await page.getByRole('textbox',{name:'Từ khóa trong tên hoặc nội dung',exact:true}).click();
  await page.keyboard.type('Kế hoạch');
  await page.getByRole('button',{name:'Lưu bộ sưu tập',exact:true}).click();
  await page.getByText('Của bạn · Kế hoạch · 1 ghi chú',{exact:true}).waitFor();
  await page.getByRole('button',{name:'Kế hoạch sáng tạo Ghi chú của bạn',exact:true}).waitFor();
  await page.waitForTimeout(700);
  await page.screenshot({path:'D:/flutter cuoi ki/evidence/2026-10-10-workspace-polish/06-collection-selection.png'});
  return {saved:true,selectedImmediately:true,matchingNotes:1};
}
