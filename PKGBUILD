# Maintainer: Jerry Fan <nano@pixelcollider.net>

pkgname=conmon
pkgver=1.0.0
pkgrel=1
pkgdesc='Restart service when some criterion fails'
arch=('any')
url='https://github.com/TheGuardianWolf/conmon'
license=('custom')
depends=()
md5sums=('30be2accc62f43ea0ba23157fdda6ed5'
         '956824b0177900c1036f3da3c18ab867'
         'aa65095671de8930dd14ffbab8504119'
         '7246f848faa4e9c9fc0ea91122d6e680')

source=('conmon.sh' 
		'conmon@.service' 
		'template.conf' 
		'UNLICENSE')

package() {
	install -Dm755 conmon.sh ${pkgdir}/usr/bin/conmon
	install -Dm644 conmon@.service ${pkgdir}/etc/systemd/system/conmon@.service
	install -Dm644 template.conf ${pkgdir}/etc/conmon/template.conf
	install -Dm644 UNLICENSE ${pkgdir}/usr/share/licenses/$pkgname/UNLICENSE
}
