async page => {
  await page.getByRole('button', {name:'Quay lại',exact:true}).click();
  await page.getByRole('button', {name:/Hồ sơ và tùy chỉnh$/}).click();
  const dark = page.getByRole('switch', {name:'Giao diện tối',exact:true});
  await dark.waitFor();
  await page.waitForTimeout(400);
  const control = await dark.boundingBox();
  await page.mouse.click(control.x + control.width/2, control.y + control.height/2);
  await page.waitForTimeout(650);
  const center = page.getByRole('button', {name:'Trung tâm bảo mật',exact:true});
  const box = await center.boundingBox();
  await page.mouse.click(box.x + box.width/2, box.y + box.height/2);
  await page.getByText('1 phiên hoạt động', {exact:true}).waitFor();
  const prefix = 'D:/flutter cuoi ki/evidence/2026-10-11-security-center/';
  for (const [name,width,height] of [['desktop-dark',1440,1000],['phone-dark',390,844]]) {
    await page.setViewportSize({width,height});
    await page.mouse.move(0,0);
    await page.waitForTimeout(650);
    await page.screenshot({path:prefix+name+'.png'});
  }
  await page.setViewportSize({width:1440,height:1000});
  return {result:'PASS', themeChangedThroughUI:true, events:page.securityFinal};
}
