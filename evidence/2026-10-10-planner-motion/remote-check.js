async page => {
 const root='D:/flutter cuoi ki/evidence/2026-10-10-planner-motion/';
 const shot=async name=>{await page.mouse.move(5,1075);await page.waitForTimeout(600);await page.screenshot({path:root+name,scale:'css'});};
 await page.getByText('Ghi chú không còn khả dụng.',{exact:true}).waitFor();
 await shot('13-calendar-remote-lock-dark.png');
 await page.getByRole('button',{name:'Đóng',exact:true}).click();
 await page.getByText('Ghi chú bị khóa, mất quyền hoặc tài khoản đã thay đổi.',{exact:true}).waitFor();
 if(!await page.getByRole('button',{name:'Lưu kế hoạch',exact:true}).isDisabled())throw new Error('Stale form still allows save');
 await page.getByRole('button',{name:'Hủy',exact:true}).click();
 await page.getByText('2 ghi chú trong kế hoạch',{exact:true}).waitFor();
 if(await page.getByRole('group',{name:/^Thông tin cần bảo vệ/}).count())throw new Error('Protected card retained');
 await shot('14-board-remote-lock-dark.png');
 return {passed:true,calendarRemoved:true,staleFormDisabled:true,protectedCardHidden:true,visiblePlans:2};
}
