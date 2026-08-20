document.addEventListener("DOMContentLoaded", () => {
    const loadComponent = async (id, file) => {
        try {
            const response = await fetch(file);
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
            const data = await response.text();
            
            const container = document.getElementById(id);
            if (container) {
                container.innerHTML = data;
                if (id === "header-placeholder") {
                    highlightCurrentPage();
                }
            }
        } catch (error) {
            console.error(`Error cargando el componente ${file}:`, error);
        }
    };

    const highlightCurrentPage = () => {
        const path = window.location.pathname;
        const currentPage = path.split("/").pop() || "index.html";
        const links = document.querySelectorAll(".navbar__link");

        links.forEach(link => {
            const href = link.getAttribute("href");
            if (href === currentPage) {
                link.classList.add("navbar__link--active");
                link.setAttribute("aria-current", "page");
            } else {
                link.classList.remove("navbar__link--active");
                link.removeAttribute("aria-current");
            }
        });
    };

    loadComponent("header-placeholder", "assets/components/header.html");
    loadComponent("footer-placeholder", "assets/components/footer.html");
});