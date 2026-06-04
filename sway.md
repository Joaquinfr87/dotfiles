# Guia de instalacion SWAY - DEBIAN
Al tener una instalacion fresca de debian, se redactar los pasos que se tienen que realizar para tener sway configurado

## SUDO
```bash
 su -
```
Ingresas tu contrasena del root

```bash
apt install sudo
sudo usermod -aG sudo {nombre_usuario}
exit #sale root
exit #sale al tty
```
Logeas con tu tty
## BASE
Instalar herramientas necesarias
```bash
sudo apt install firefox-esr sway git curl unzip wl-clipboard 
zsh zsh-autosuggestions zsh-syntax-highlighting
lazygit tree-sitter-cli build-essential fzf ripgrep fd-find
```
Anade la cuenta de firefox para tener los pluggins, anade la cuenta de gmail, asi tambien como la de github

### GIT
anadir el git config
```bash
git config --global user.name "Joaquin Alessandro Felipez Rojas"
git config --global user.email "joaquinfelipezrojas@gmail.com"
```
generara la clave ssh, deja la passphrase vacia
```bash
ssh-keygen -t rsa -b 4096 -C "joaquinfelipezrojas@gmail.com"
```
Iniciar el agente
```bash
eval "$(ssh-agent -s)"
```
agregar la clave al agente ssh, y copiar la clave a ssh config github.
```bash
ssh-add ~/.ssh/id_rsa
cat ~/.ssh/id_rsa.pub | wl-copy
```
Clonar el repo de github dotfiles
```bash
mkdir ~/repos
cd ~/repos
git clone  git@github.com:Joaquinfr87/dotfiles.git
cd ~
```
## KITTY
Instalar por script de la pagina oficial [Kitty](https://sw.kovidgoyal.net/kitty/)
```bash
curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
```
copiar los enlaces simbolicos para el bin
```bash
mkdir -p ~/.local/{bin,share}
ln -s ~/.local/kitty.app/bin/kitty ~/.local/bin/kitty
ln -s ~/.local/kitty.app/bin/kitten ~/.local/bin/kitten
cp -as ~/.local/kitty.app/share/* ~/.local/share/
```
enlazar config dotfiles con la maquina
```bash
rm -rf ~/.config/kitty
cp -r ~/repos/dotfiles/kitty ~/.config/
```
instalar fuente personalizada o
escoger una fuente de NerdFont o utilizar la recomendada por p10k
### NerdFont 
dirigirte a la pagina de [Nerd Font](https://www.nerdfonts.com/font-downloads) y descargar la fuente que gustes
```bash
 mkdir -p ~/.local/share/fonts/{fuente-NerdFonts}
 unzip ~/Downloads/{fuente-NerdFonts}.zip -d ~/.local/share/fonts/{fuente-NerdFonts}/
 fc-cache -fv
```
### Meslo
```bash
mkdir -p ~/.local/share/fonts/Meslo
cd ~/.local/share/fonts/Meslo

wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf
wget https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf

cd ~
fc-cache -fv
```
cambiar la fuente
```bash
kitten choose-fonts
```
cambiar el tema
```bash
kitten themes
```

## ZSH
cambiar la shell 
```bash
chsh -s $(which zsh)
```
instalar [oh-my-zsh](https://github.com/ohmyzsh/ohmyzsh/)
```bash
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
```
instalar [p10k](https://github.com/romkatv/powerlevel10k)
```bash
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
```
copiar la config
```bash
cp ~/repos/dotfiles/{.zprofile,.zshrc} ~/
```
configurar p10k
```bash
p10k configure
```

## NVIM
Descargar e instalar [Rust](https://rust-lang.org/tools/install/)
```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```
Instalar por medio del script [Bob](https://github.com/mordechaihadad/bob)
```bash
curl -fsSL https://raw.githubusercontent.com/MordechaiHadad/bob/master/scripts/install.sh | bash
```
Instalar nvim
```bash
bob use stable
```
> *Nota*: para actualizar nvim bob update stable

anadir un enlace de nvim al share
```bash
sudo cp -as ~/.local/share/bob/{nvim-version}/share/* /usr/share/
```

anadir un enlace al root
```bash
sudo ln -s ~/.local/share/bob/nvim-bin/nvim /usr/bin/
```


Limpiar configuración previa de Neovim

```bash
rm -rf ~/.config/nvim
rm -rf ~/.local/share/nvim
rm -rf ~/.local/state/nvim
rm -rf ~/.cache/nvim
```

Enlazar configuración de Neovim

```bash
cp -r ~/repos/dotfile/nvim ~/.config/
```

> **Nota:** La primera vez que ejecutes `nvim`, LazyVim instalará automáticamente todos los plugins. Esto puede tardar unos minutos.


