async page => {
 await page.getByRole('group',{name:/Đã chia sẻ cho 2 người Thiết kế NoteTogether/}).click();
 return {editorOpened:true};
}
