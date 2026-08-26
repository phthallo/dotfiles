* {
	background-image: none;
	box-shadow: none;
}

window {
	background-color: {{bg_rgba}};
}

button {
    border-color: {{overlay}};
	text-decoration-color: {{fg}};
    color: {{fg}};
	background-color: {{surface_rgba}};
	border-style: solid;
	border-width: 1px;
	background-repeat: no-repeat;
	background-position: center;
	background-size: 25%;
	border-radius: 7px;
	margin: 1rem;
}

button:focus, button:active, button:hover {
	background-color: {{accent_rgba}};
	outline-style: none;
}

#lock {
    background-image: url("{{icon_dir}}/lock.svg");
}

#logout {
    background-image: url("{{icon_dir}}/logout.svg");
}

#suspend {
    background-image: url("{{icon_dir}}/suspend.svg");
}

#hibernate {
    background-image: url("{{icon_dir}}/hibernate.svg");
}

#shutdown {
    background-image: url("{{icon_dir}}/shutdown.svg");
}

#reboot {
    background-image: url("{{icon_dir}}/reboot.svg");
}
