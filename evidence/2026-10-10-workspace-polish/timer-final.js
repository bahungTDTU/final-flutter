async page => {
  const paused = await page.getByText(/^Thời gian còn lại/).textContent();
  await page.reload();
  await page.locator('flt-semantics-placeholder').evaluate(el=>el.click());
  await page.getByRole('button',{name:'Không gian làm việc',exact:true}).first().click();
  await page.getByRole('checkbox',{name:'Tập trung',exact:true}).click();
  await page.getByRole('button',{name:'Tiếp tục',exact:true}).waitFor();
  const restored = await page.getByText(/^Thời gian còn lại/).textContent();
  if (paused !== restored) throw new Error('Paused timer changed after reload');
  await page.getByRole('button',{name:'Mục tiêu mỗi ngày 6 phiên',exact:true}).waitFor();
  await page.getByRole('button',{name:'Tiếp tục',exact:true}).click();
  await page.getByRole('button',{name:'Tạm dừng',exact:true}).waitFor();
  await page.waitForTimeout(2100);
  await page.getByRole('button',{name:'Tạm dừng',exact:true}).click();
  await page.getByRole('button',{name:'Tiếp tục',exact:true}).waitFor();
  const afterResume = await page.getByText(/^Thời gian còn lại/).textContent();
  if (afterResume === restored) throw new Error('Timer did not advance after resume');
  await page.waitForTimeout(700);
  await page.screenshot({path:'D:/flutter cuoi ki/evidence/2026-10-10-workspace-polish/15-focus-reload-dark.png'});
  return {paused,restored,afterResume,goal:6,passed:true};
}

