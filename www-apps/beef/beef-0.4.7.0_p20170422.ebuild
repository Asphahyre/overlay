# Copyright 1999-2017 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

EAPI=5

USE_RUBY="ruby23"

inherit ruby-single ruby-ng multilib user

DESCRIPTION="The Browser Exploitation Framework"
HOMEPAGE="https://beefproject.com/"
COMMIT="f9f30eb49d00b0ed97d8ebdfa66916dadf68c7b9"
SRC_URI="https://github.com/beefproject/${PN}/archive/${COMMIT}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"

SLOT=0
KEYWORDS="~amd64 ~x86"
IUSE=""

RUBY_S="${PN}-${COMMIT}"
DEPEND="dev-libs/openssl"
RDEPEND="${DEPEND} ${RUBY_DEPS}"

ruby_add_bdepend "dev-ruby/bundler-audit"
ruby_add_rdepend "dev-ruby/eventmachine www-servers/thin dev-ruby/sinatra dev-ruby/dm-core dev-ruby/rack:2.0 dev-ruby/em-websocket dev-ruby/uglifier:3 dev-ruby/mime-types dev-ruby/execjs:0 dev-ruby/ansi dev-ruby/term-ansicolor dev-ruby/json:2 dev-ruby/data_objects dev-ruby/dm-sqlite-adapter dev-ruby/rubyzip:1 dev-ruby/espeak-ruby dev-ruby/nokogiri dev-ruby/therubyracer dev-ruby/geoip dev-ruby/parseconfig dev-ruby/erubis dev-ruby/dm-migrations dev-ruby/rubydns dev-ruby/dm-serializer dev-ruby/qr4r dev-ruby/msfrpc-client"

all_ruby_prepare() {
	# fix too strict versioning
	rm Gemfile.lock
	sed -i -e '/rubydns/ s/~> 0\.7\.3/~> 1.0/' Gemfile || die
}

each_ruby_prepare() {
	BUNDLE_GEMFILE=Gemfile ${RUBY} -S bundle install --local || die
	BUNDLE_GEMFILE=Gemfile ${RUBY} -S bundle check || die
}

pkg_setup() {
	enewgroup beef
}

src_install() {
	cat >beef <<EOF
#!/usr/bin/$USE_RUBY
require 'rubygems'

ENV['BUNDLE_GEMFILE'] = '/usr/$(get_libdir)/${PN}/Gemfile'

load '/usr/$(get_libdir)/${PN}/${PN}'
EOF

	chmod +x beef
	dobin beef

	cd "${USE_RUBY}"/"${RUBY_S}"

	tools/generate-certificate || die

	sed -i -e "s:#{\$root_dir}/config.yaml:/etc/beef/config.yaml:" beef || die

	sed -i -e "s#\"\(.*\.pem\)\"#\"/usr/$(get_libdir)/beef/\1\"#" config.yaml || die
	sed -i -e "s#/opt/GeoIP/GeoLiteCity.dat#/usr/share/GeoIP/GeoLiteCity.dat#" config.yaml || die

	dodir /usr/$(get_libdir)/beef
	insinto /usr/$(get_libdir)/beef
	doins -r arerules beef beef_cert.pem beef_key.pem core extensions modules test tools Gemfile Gemfile.lock Rakefile

	dodir /etc/beef
	insinto /etc/beef
	doins config.yaml
}

pkg_postinst() {
	chown -R root:beef /usr/$(get_libdir)/beef
	chmod -R g+w /usr/$(get_libdir)/beef

	einfo "You should modify the configuration at /etc/beef/config.yaml"
	einfo "and change the admin password from 'beef:beef'."
	einfo
	einfo "Add unprivileged users that will run BeEF to the 'beef' group."
}
