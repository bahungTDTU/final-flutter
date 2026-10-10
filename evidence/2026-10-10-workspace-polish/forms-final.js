async page => {
 await page.getByRole('checkbox',{name:'Mẫu riêng',exact:true}).click();
 await page.getByRole('button',{name:'Tạo mẫu riêng',exact:true}).click();
  const title=page.getByRole('textbox',{name:'Tên mẫu',exact:true});
  await title.click(); await page.keyboard.press('Control+A'); await page.keyboard.press('Backspace');
  const desc=page.getByRole('textbox',{name:'Mô tả ngắn',exact:true});
  await desc.click(); await page.keyboard.type('Giữ nội dung khi có lỗi');
  await page.getByRole('button',{name:'Lưu mẫu',exact:true}).click();
  await page.getByText('Mẫu cần tiêu đề, nội dung hợp lệ và mô tả tối đa 140 ký tự.',{exact:true}).waitFor();
  await page.waitForTimeout(700);
  await page.screenshot({path:'D:/flutter cuoi ki/evidence/2026-10-10-workspace-polish/04-template-error.png'});
  await desc.click();
  if (await desc.inputValue() !== 'Giữ nội dung khi có lỗi') throw new Error('Description lost after validation');
  await title.click(); await page.keyboard.type('Mẫu kế hoạch mới');
  await page.getByRole('button',{name:'Lưu mẫu',exact:true}).click();
  await page.getByRole('button',{name:'Xóa mẫu',exact:true}).waitFor();
  await page.getByRole('button',{name:'Xóa mẫu',exact:true}).click();
  await page.getByRole('button',{name:'Xóa',exact:true}).waitFor();
  await page.waitForTimeout(700);
  await page.screenshot({path:'D:/flutter cuoi ki/evidence/2026-10-10-workspace-polish/05-delete-confirm.png'});
  await page.getByRole('button',{name:'Hủy',exact:true}).click();
  await page.getByText('Mẫu kế hoạch mới',{exact:true}).waitFor();
  await page.getByRole('checkbox',{name:'Bộ sưu tập',exact:true}).click();
  await page.getByRole('checkbox',{name:'Tạo bộ sưu tập',exact:true}).click();
}

