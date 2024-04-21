module main

import net.http
import net.html
import os

fn parse( mut url_list []string, url string)  {
	contents := http.get(url) or {
		panic('Error finding the url')
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
	return !end.contains('.')
}

fn main() {
	initial_url := 'http://wp.test'

	file := setup()

	unsafe {
		mut links := []string{}

		parse(mut links, initial_url)

		mut read_links := []string{}

		for {
			if links.len == 0 { break }
			mut link := links[0].str()
			if link.split('')[0] == '/' { link = '$initial_url$link' }

			if read_links.contains(link) {
				links.delete(0)
				continue
			}
			links.delete(0)
			write_to_file(file, link)
			print('$link\n')
			read_links << link

			if check_if_valid_link(link) {
				parse(mut links, link)
			}

		}
	}

}
