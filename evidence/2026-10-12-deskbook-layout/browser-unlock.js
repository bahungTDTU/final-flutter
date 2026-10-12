async page => {
  if (await page.getByText('Bản ghi riêng tư',{exact:true}).count()) throw Error('Private title before grant');
  await page.mouse.move(0,0);
  await page.screenshot({path:'output/playwright/deskbook-ui/protected-gate-desktop-dark.png'});
  await page.setViewportSize({width:390,height:844});
  await page.waitForTimeout(300);
  await page.screenshot({path:'output/playwright/deskbook-ui/protected-gate-phone-dark.png'});
  await page.setViewportSize({width:1440,height:1000});
  await page.getByRole('textbox',{name:'Mật khẩu ghi chú',exact:true}).fill('note-password-123');
  await page.getByRole('button',{name:'Mở khóa',exact:true}).click();
  await page.getByRole('textbox',{name:'Tiêu đề',exact:true}).waitFor();
  await page.waitForTimeout(300);
  await page.screenshot({path:'output/playwright/deskbook-ui/protected-reader-desktop-dark.png'});
  return {privateTitleHiddenBeforeGrant:true,unlockedSyntheticReader:true,
    appErrors:page.deskbook.errors,consoleErrors:page.deskbook.consoleErrors};
}
