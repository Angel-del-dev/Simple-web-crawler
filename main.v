module main

import net.http
import net.html
import os
import time

fn parse( mut url_list []string, url string)  {
	contents := http.get(url) or {
		panic('Error finding the url <<$url>>')
	}

	body := html.parse(contents.str())
	links := body.get_tags(name: 'a')

	for a in links {
		link := a.attributes['href'].str().replace('//', '/')
		url_list << link
	}
}

fn setup() string {
	folder := 'out'
	file := 'list.links'
	if !os.is_dir(folder) {
		os.mkdir(folder) or {
			panic('$folder folder could not be created')
		}
	}

	if !os.is_file('$folder/$file') {
		os.create('$folder/$file') or {
			panic('Could not create $file')
		}
	}
	return '$folder/$file'
}

fn write_to_file(file string, link string) {
	mut contents := os.read_file(file) or {
		panic('Could not find $file')
	}

	if contents != '' {
		contents += '\n'
	}

	os.write_file(file, '$contents$link') or {
		panic('Could not write $file')
	}
}

fn check_if_valid_link(link string) bool {
	mut link_arr := link.split('/')

	end := link_arr.pop()
	return !end.contains('.') && link.split('')[0] != '.'
}

fn seconds_to_nano_seconds(seconds f32) f32 {
	return seconds * 1_000_000
}

fn get_domain_from_url(url string) string {

	if url.split('')[0] == '/' { return '' }
	mut domain := ''
	mut new_url := url.split('://')

	if new_url.len > 1 {
		rest := new_url[1].split('/')
		domain = new_url[0]+'://'+rest[0]
	}
	return domain
}

fn main() {
	initial_url := os.args[1]
	file := setup()
	nanoseconds := seconds_to_nano_seconds(0.2)

	unsafe {
		mut links := []string{}
		mut domains := []string{}

		domains << get_domain_from_url(initial_url)

		parse(mut links, initial_url)

		mut read_links := []string{}
		for {
			if links.len == 0 { break }
			mut link := links[0].str()

			new_domain :=  get_domain_from_url(link)

			if new_domain == '' { domains << domains.last() }
			else {
				domains << new_domain
			}

			current_domain := domains.last()

			if link.split('')[0] == '/' {
				link = '$current_domain$link'
			}
			domains.pop()

			if read_links.contains(link) {
				links.delete(0)
				time.sleep(nanoseconds)
				continue
			}
			links.delete(0)
			write_to_file(file, link)
			read_links << link

			if check_if_valid_link(link) {
				parse(mut links, link)
			}
			time.sleep(nanoseconds)
		}
	}

}