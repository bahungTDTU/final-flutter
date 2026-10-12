async page => {
  await page.mouse.move(0,0);
  await page.screenshot({path:'output/playwright/atelier-ui/profile-desktop-dark.png'});
  await page.setViewportSize({width:390,height:844});
  await page.waitForTimeout(300);
  await page.screenshot({path:'output/playwright/atelier-ui/profile-phone-dark.png'});
  await page.setViewportSize({width:1440,height:1000});
  const security=page.getByRole('button',{name:'Trung tâm bảo mật',exact:true});
  await security.focus();
  await security.press('Enter');
  return {keyboardSecurityNavigation:true};
}
