async page => {
  await page.getByRole('button',{name:'Hỏi ghi chú',exact:true}).click();
  await page.mouse.move(0,0);
  await page.waitForTimeout(300);
  await page.screenshot({path:'output/playwright/atelier-ui/ai-desktop-dark.png'});
  await page.setViewportSize({width:390,height:844});
  await page.waitForTimeout(300);
  await page.screenshot({path:'output/playwright/atelier-ui/ai-phone-dark.png'});
  await page.setViewportSize({width:1440,height:1000});
  await page.getByRole('button',{name:'Ghi chú',exact:true}).click();
  await page.getByRole('button',{name:'Không gian làm việc',exact:true}).first().click();
  return {aiProviderRequest:false, appErrors:page.atelier.errors,consoleErrors:page.atelier.consoleErrors};
}
