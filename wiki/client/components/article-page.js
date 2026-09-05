export function showArticlePage(article) {
  document.querySelector('.page')?.classList.remove('is-home');
  document.querySelectorAll('.page > *').forEach((element) => {
    element.hidden = element !== article;
  });
  article.hidden = false;
  window.scrollTo(0, 0);
}
