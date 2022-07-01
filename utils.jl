using Base.Meta: isexpr
using Dates

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

function hfun_all_images()
    # some code here which defines "generated_html"
    # as a String containing valid HTML
    generated_html = ""
    for image in readdir("images")
        generated_html *= string("<img src=\"",string("/images/",image),"\">")
    end
    return generated_html
end

macro get(ex)
    @assert isexpr(ex, :call)
    method = first(ex.args)
    varname = last(ex.args)
    return :(let
        var = $(esc(ex))
        @assert !isnothing(var) string("$($(method)) `$($(varname))` isn't defined: ",
                                       $(method), '(', join(repr.([$(map(esc, ex.args[2:end])...)]), ", "), ')', # call args
                                       )
        var
    end)
end

# Meta stuff from here on down
# taken directly from https://github.com/aviatesk/aviatesk.github.io/blob/68cea5c5f5ffaa55a2c247d50b6cb2702f993b1d/utils.jl
# (thanks!)

const SITE_TITLE = globvar(:website_title)
const SITE_DESC  = globvar(:website_descr)
const SITE_URL   = globvar(:website_url)
const TWITTER_ID = "@finnhambly"
const DATE_FORMAT = dateformat"yyyy-mm-dd"

macro get(ex, default)
    @assert isexpr(ex, :call)
    method = first(ex.args)
    varname = last(ex.args)
    return :(let
        var = $(esc(ex))
        isnothing(var) ? $(esc(default)) : var
    end)
end

is_blogpost(path = locvar(:fd_rpath)) = "blog" in splitpath(path)
get_pubdate(url) = Date(@get(pagevar(url, :pubdate), today_s()), DATE_FORMAT)
get_pubdate()    = Date(@get(locvar(:pubdate), today_s()), DATE_FORMAT)
today_s() = Dates.format(today(), DATE_FORMAT)

function hfun_meta()
    url            = joinpath(SITE_URL, strip(get_url(locvar(:fd_rpath)), '/'))
    title          = @get(locvar(:title), SITE_TITLE)
    desc           = @get(locvar(:rss), SITE_DESC)
    img            = @get(locvar(:image), joinpath(SITE_URL, "/images/me.jpeg"))
    type           = is_blogpost() ? "article" : "website"
    published_time = get_pubdate()

    return """
    <meta property="og:url" content="$(url)" />
    <meta property="og:title" content="$(title)" />
    <meta property="og:image" content="$(img)" />
    <meta property="og:type" content="$(type)" />
    <meta property="og:description" content="$(desc)" />
    <meta property="og:published_time" content="$(published_time)" />
    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:description" content="$(desc)" />
    <meta name="twitter:site" content="$(TWITTER_ID)" />
    <meta name="twitter:creator" content="$(TWITTER_ID)" />
    """
end