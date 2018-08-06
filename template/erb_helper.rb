def lorem()
    "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
end




def image(src, caption)
    <<"EOS"
<figure>
<img src='http://localhost:9999/#{src}' style='width: 30%;'>
<br>
<figcaption>#{caption}</figcaption>
</figure>
EOS
end