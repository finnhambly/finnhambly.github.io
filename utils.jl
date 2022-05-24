function hfun_bar(vname)
  val = Meta.parse(vname[1])
  return round(sqrt(val), digits=2)
end

function hfun_m1fill(vname)
  var = vname[1]
  return pagevar("index", var)
end

function lx_baz(com, _)
  # keep this first line
  brace_content = Franklin.content(com.braces[1]) # input string
  # do whatever you want here
  return uppercase(brace_content)
end

"""
    {{blogposts}}

Plug in the list of blog posts contained in the `/blog` folder.
Source: https://github.com/abhishalya/abhishalya.github.io
"""
@delay function hfun_blogposts()
    today = Dates.today()
    curyear = year(today)
    curmonth = month(today)
    curday = day(today)

    list = readdir("blog")
    filter!(endswith(".md"), list)
    function sorter(p)
        ps  = splitext(p)[1]
        url = "/blog/$ps/"
        surl = strip(url, '/')
        pubdate = pagevar(surl, "published")
        if isnothing(pubdate)
            return Date(Dates.unix2datetime(stat(surl * ".md").ctime))
        end
        return Date(pubdate, dateformat"yyyy-mm-dd")
    end
    sort!(list, by=sorter, rev=true)

    io = IOBuffer()
    write(io, """<p class="blog-posts">""")
    for (i, post) in enumerate(list)
        if post == "index.md"
            continue
        end
        ps = splitext(post)[1]
        write(io, "<p><i>")
        url = "/blog/$ps/"
        surl = strip(url, '/')
        title = pagevar(surl, "title")
        pubdate = pagevar(surl, "published")
        description = pagevar(surl, "rss_description")
        if isnothing(pubdate)
            date = "$curyear-$curmonth-$curday"
        else
            date = Date(pubdate, dateformat"yyyy-mm-dd")
        end
        write(io, """$date</i> &nbsp; <b><a href="$url">$title</a></b><br>""")
        write(io, """<i class="description">$description</i><p>""")
    end
    write(io, "</p>")
    return String(take!(io))
end
