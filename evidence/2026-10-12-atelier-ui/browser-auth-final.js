async page => {
  await page.mouse.move(0,0);
  await page.waitForTimeout(350);
  await page.screenshot({path:'output/playwright/atelier-ui/auth-desktop-light.png'});
  await page.setViewportSize({width:390,height:844});
  await page.waitForTimeout(350);
  await page.screenshot({path:'output/playwright/atelier-ui/auth-phone-light.png'});
  return {finalAuth:true,appErrors:page.atelier.errors,consoleErrors:page.atelier.consoleErrors};
}
