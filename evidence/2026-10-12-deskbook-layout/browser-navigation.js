async page => {
 const shot=async name=>{await page.mouse.move(0,0);await page.waitForTimeout(300);await page.screenshot({path:`output/playwright/deskbook-ui/${name}.png`});};
 await page.getByRole('button',{name:'Quay lại',exact:true}).click();
 await page.getByRole('button',{name:'Không gian làm việc Kế hoạch, việc cần làm và tập trung',exact:true}).click();
 await shot('workspace-desktop-dark');
 await page.getByRole('button',{name:'Quay lại',exact:true}).click();
 await page.getByRole('button',{name:'Hỏi ghi chú',exact:true}).click();
 await shot('ai-desktop-dark');
 await page.setViewportSize({width:390,height:844});
 await shot('ai-phone-dark');
 await page.getByRole('button',{name:'Ghi chú',exact:true}).click();
 await page.getByRole('button',{name:'Công cụ thư viện',exact:true}).click();
 await shot('library-tools-phone-dark');
 return {workspaceOpened:true,aiNavigation:true,aiProviderRequest:false,phoneToolsOpened:true,appErrors:page.deskbook.errors,consoleErrors:page.deskbook.consoleErrors};
}
