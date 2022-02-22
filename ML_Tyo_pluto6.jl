### A Pluto.jl notebook ###
# v0.18.0

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ d7ac6a44-843f-48da-b90d-576658f33d84
begin
	using PlutoUI
	using Plots
end

# ╔═╡ 2c74a643-2db6-4693-bd46-47560b7036fb
using Statistics

# ╔═╡ f7fd08ce-78fb-11ec-2e93-5bcd26561b10
md"""
# 4. 勾配法によるパラメータ推定
## 4.1. パラメータ推定の閉じた式
## 4.2. 閉じた式の問題点
## 4.3. 最急降下法
### 4.3.1. 最急降下法の更新式
### 4.3.2. 最急降下法の実行例
```math
\begin{eqnarray}
f(x)  & = & 0.5x^2 - 5x + 13.5 & = & \frac{1}{2} \{(x-5)^2 + 2\} \\
f'(x) & = & \frac{∂f(x)}{∂x} = x-5
\end{eqnarray}
```
"""

# ╔═╡ 673191fe-f287-453a-b396-28a234132f11
f(x) = 0.5((x - 5)^2 + 2)

# ╔═╡ e114148e-10a1-4d42-89ea-1b41c5c2393b
g(x) = x - 5

# ╔═╡ 5c5e89e7-69d6-40d6-a340-834338c18c8b
function sd(f, g; x=0., η=0.01, ϵ=1e-4)
	t = 1
	H = []
	while true
		gx = g(x)
		push!(H, Dict("t"=>t,"x"=>x,"fx"=>f(x),"gx"=>g(x)))
		-ϵ < gx < ϵ && break
		x -= η * gx
		t += 1
	end
	return H
end

# ╔═╡ 74fa366c-e9b9-4668-8ac5-b82090e47006
function draw_step(h, η)
	
	x = range(0,10,length=1000)

	plot!(x, f.(x); c=:black, lw=1.5)
	
	xt, yt, gt = h["x"], h["fx"], h["gx"]

	# 接線の描画
	y0 = yt - xt * gt
	y10 = (10 - xt) * gt + yt
	tangent_line = [(0, y0), (10, y10)]
	plot!(tangent_line; c=:blue, lw=1.5)

	# 次の位置までの差を線分で描画
	next_diff = [(xt, yt), (xt - gt*η, yt)]
	plot!(next_diff; c=:green, lw=1.5)

	# 現在位置のx軸を描画
	vline!([xt]; c=:red, lw=1.5, ls=:dash)

	# 現在位置を描画
	scatter!([(xt, yt)]; c=:red, ms=5, markerstrokewidth=0)

	# 注釈を描画
	msg = "$(round(gt*η; digits=5))"
	annotate!([(xt-gt*η*0.5,yt+0.3,text(msg, 10, :center, :black))])
	msg2 = "$(round(xt; digits=5))"
	annotate!([(xt+0.2,yt-0.4,text(msg2, 10, :left, :black))])
end

# ╔═╡ 3066a735-924f-437f-a67c-1632c14d86a9
begin
	η = 0.5
	H = sd(f, g, x=9, η=η)
	@bind now Slider(1:length(H), show_value=true)
end

# ╔═╡ 5fbd3837-49a0-44f2-973e-9d15dbf5bc43
let
	plot(size=(500,500), xlim=(0,10), ylim=(0,10), framestyle=:box, legend=false)
	plot!(xlabel="x", ylabel="y")

	# anim = @animate for h in H
	# 	draw_step(H, η)
	# end
	# gif(anim, "gd.gif"; fps=2)
	
	draw_step(H[now], η)
end

# ╔═╡ f98e68cd-ffcc-4c73-890a-2cf34a828237
let
	plot(size=(600,400), framestyle=:box, xlim=(0,18), ylim=(0,10),
		xticks=0:2:18, yticks=1:1:10, legend=false)
	plot!(xlabel="t", ylabel="f(x)")

	ts = [h["t"] for h in H]
	fxs = [h["fx"] for h in H]
	plot!(ts, fxs; ls=:solid, shape=:auto, c=:blue)
end

# ╔═╡ a1a399f0-6a95-4003-879a-11cc0fc86049
md"""
## 4.4. 最急降下法によるパラメータ推定
### 4.4.1. 最急降下法の実装
"""

# ╔═╡ 368c6ea8-1aa8-4c38-8700-73c79c74bac9
D = [1 3; 3 6; 6 5; 8 7]

# ╔═╡ 6f5ecb62-c5d0-48aa-89a2-bee19cb2db4e
md"""
```math
\begin{eqnarray}
w^{t+1} & = & {\bf w}^{(t)} - \eta_t ∇L̂_D({\bf w}^{(t)}) \\
        & = & {\bf w}^{(t)} - 2\eta_t {\bf X}^{\rm T}({\bf ŷ}^{(t)} - {\bf y}) \\
        & = & {\bf w}^{(t)} - 2\eta_t \sum_{i=1}^{N} (ŷ_{i}^{(t)} - y_i){\bf x_i} \\

\end{eqnarray}
```
"""

# ╔═╡ f51adce8-b749-4453-b9c9-849e874c45ee
append!(D[:,1], one(D[1]))

# ╔═╡ 0289da34-98e8-4d4e-8243-00d48147c432
 function calc_gd()
	 max_epochs = 10_000
	 η = 0.001
	 ϵ = 1e-4

	 X = hcat(D[:,1], ones(length(D[:,1])))
	 y = D[:,2]
	 w = zeros(size(X)[2])
	 t = 0
	 
	 for tmp in 1:max_epochs
	 	 ŷ = X * w
		 grad =  2X' * (ŷ - y)
		 if sum(abs.(grad)) < ϵ
			 t = tmp-1
			 break
		 end
		 w -= η*grad
	 end
	 return w, t
 end

# ╔═╡ 2205b8cf-10d9-4594-82c2-20f92753c91c
calc_gd()

# ╔═╡ bdfac505-181f-489a-aaf5-f90d06f9f685
md"""
## 4.5. 確率的勾配降下法
## 4.6. 確率的勾配降下法によるパラメータ推定
### 4.6.1 確率的勾配降下法による回帰モデルの学習

**確率的勾配降下法による線形回帰パラメータ更新式**

```math
\begin{eqnarray}
{\bf w}^{(t+1)} & = & {\bf w}^{(t)} - 2\eta_t (ŷ_i^{(t)} - y_i){\bf x}_i
\end{eqnarray}
```
"""

# ╔═╡ 6c1d8bdc-2d10-4185-9118-505f1044cf52
 function calc_sgd()
	 max_epochs = 40_000
	 η0 = 0.03
	 ϵ = 1e-4

	 X = hcat(D[:,1], ones(length(D[:,1])))
	 y = D[:,2]
	 w = zeros(size(X)[2])
	 t = 0
	 
	 for t in 1:max_epochs
		 η = η0 / √t
		 i = rand(1:size(X)[1])
	 	 ŷ = X[i,:]' * w
		 grad =  2 * (ŷ - y[i]) * X[i,:]
		 if sum(abs.(grad)) < ϵ
			 break
		 end
		 w -= η*grad
	 end
	 return w
 end

# ╔═╡ c69d0f2d-7b30-4210-a90e-321874edca46
calc_sgd()

# ╔═╡ 6f9ef0b1-a92d-47f2-b0b8-cdf4067ee010
md"""
## 4.7. 確率的勾配降下法の特徴
### 4.7.1. 頻繁なパラメータ更新
"""

# ╔═╡ 17c6fd35-36c3-492e-966b-0f49428c24a6
md"""
### 4.7.2. 極小解に接近したのち振動
"""

# ╔═╡ 83c82cfc-b23c-414f-99a0-f77172f317b2
let
	plot(size=(400,400), framestyle=:box, xlim=(0,10), ylim=(0,10),
		xticks=0:2:10, yticks=0:2:10, legend=false)
	plot!(xlabel="x", ylabel="y")
	scatter!(D[:,1], D[:,2])
end

# ╔═╡ 403cb46f-f640-4bb9-8708-2ab6d209445b
function calc_loss(x, y, a, b)
	return (y - (a*x + b))^2
end

# ╔═╡ ae3bbea4-d7dc-42f7-bf25-17378089265d
function calc_averege_loss(D, a, b)
	return calc_loss.(D[:,1], D[:,2], a, b) |> mean
end

# ╔═╡ 13380627-fc87-4245-816f-c2cb4b647db1
function calc_minimizer(D)
	cov_value = cov(D; corrected=false)
	a = cov_value[1,2] / cov_value[1,1]
	b = mean(D[:,2]) - a * mean(D[:,1])
	return a, b
end

# ╔═╡ 0dcd1a01-5ed1-4930-8f6f-b09c619b09e2
function calc_losses(a, b, D, N, minvalue)
	losses = []
	for i in range(1, size(D)[1])
		loss_now = calc_loss.(D[i,1], D[i,2], a, b) .+ minvalue
		push!(losses, loss_now)
	end
	return losses
end

# ╔═╡ 3795afa6-1705-44be-b4bf-1adbcf29e91b
function plot_heatmap(;cb=true)
	gr()
	N = 1024
	minvalue = 1e-6     # This prevents log 0 in the logarithmic scale.
	mincontour = 1e-2   # Cut-off value for the contour plot.
	A = range(-1, 7, N)
	B = range(-1, 7, N)
	losses = calc_losses(A, B', D, N, minvalue)
	J = sum(losses)'

	
	plot(xlim=(-1,7), ylim=(-1,7), framestyle=:box, aspect_ratio=1)
	plot!(xticks=-1:7, yticks=-1:7)
	plot!(xlabel="a", ylabel="b", zlabel="Loss: Mean Squared Residual (MSR)")
	heatmap!(A, B, J; colorbar_scale=:log10, clim=(10^0,10^4),
		fillcolor=cgrad(:viridis), colorbar=cb )
	
	J_levels = [1., 10.0, 100.0, 1000.0]
	contour!(A, B, J; lc=:red, lw=0.5, ls=:dash, levels= J_levels)
	
	a_, b_ = calc_minimizer(D)
	scatter!([(a_,b_)]; shape=:star5, ms=7, c=:red, label="", markerstrokewidth=0)
end

# ╔═╡ 247e18dd-8298-444a-ab32-c977b2a94996
plot_heatmap()

# ╔═╡ e69398f4-23ec-4b2c-bb15-69451d0c86ae
function fill_loss_for_checkpoints(H)
	for h in H
		h["loss"] = calc_averege_loss(D, h["a"], h["b"])
	end
end

# ╔═╡ 188fdc2e-be02-43d5-bf94-dcf527a47d66
function calc_locus()
	max_epochs = 20000
	record_period = 200
	η0 = 0.03
	ϵ = 1e-4
	
	X = hcat(D[:,1], ones(length(D[:,1])))
	y = D[:,2]
	w = zeros(size(X)[2])
	H = []
	push!(H, Dict("t"=>0,"a"=>w[1],"b"=>w[2]))
	for t in 1:max_epochs
		η = η0 / √t
	 	ŷ = X * w
		grad =  2X' * (ŷ - y) / size(X)[1]
		if sum(abs.(grad)) < ϵ
			break
		end
		w -= η*grad
		if t%record_period == 0
			push!(H, Dict("t"=>t, "a"=>w[1], "b"=>w[2]))
		end
	end
	fill_loss_for_checkpoints(H)
	return H
end

# ╔═╡ 181d24d0-5d9b-4436-9f87-fc518e4a9504
function plot_animation(H, ci)
	plot_heatmap(cb=false)
	scatter!([H[1]["a"],], [H[1]["b"],]; shape=:star6, ms=7, c=:white, label="", markerstrokewidth=0)
	for i in 1:ci
		plot!([H[i]["a"], H[i+1]["a"]], [H[i]["b"], H[i+1]["b"]];
			  lw=3, c=:white, label="")
	end
	epoch = H[ci]["t"]
	mse = H[ci]["loss"] |> x -> round(x; digits=5)
	msg = "Epoch #$epoch, MSE = $mse"
	annotate!([(3.0,-0.7,text(msg, 12, :center, :black))])
	plot!()
end

# ╔═╡ ffbf158e-8a33-4179-b2ce-95e08cb5911e
HH = calc_locus()

# ╔═╡ 4ed5272a-6442-4a61-af37-fcca09d9f45a
function plot_regression(H, ci)

	xs = [0, 10]
	ys = [0, 10]
	plot(framestyle=:box, xlim=(xs), ylim=(ys),xticks=0:2:10, yticks=0:2:10, legend=false)
	plot!(xlabel="x", ylabel="y")
	scatter!(D[:,1], D[:,2]; markerstrokewidth=0, ms=7)
	a = H[ci]["a"]
	b =	H[ci]["b"]
	x0 = xs[1]
	x1 = xs[2]

	y0 = a * x0 + b
	y1 = a * x1 + b
	plot!([x0, x1], [y0, y1]; c=:black, lw=2)
	a_txt = round(a, digits=5)
	b_txt = round(b, digits=5)
	msg = "(a, b) = ($a_txt, $b_txt)"
	annotate!([(5.0, 0.3,text(msg, 12, :center, :black))])
	
end

# ╔═╡ 2dc05c65-d8a4-4539-8650-40f457b0ff13
@bind ci Slider(1:length(HH)-1, show_value=true)

# ╔═╡ fff206d6-ea3a-49b0-b90b-7a04afb24fb7
let
	p1 = plot_animation(HH, ci)
	p2 = plot_regression(HH, ci)
	
	plot(p1, p2; layout=(@layout [a b]), size=(900,450))
end

# ╔═╡ 4abdbcdd-bd81-4c01-a984-dd6ee1b64632
function calc_plot_sgd()
	max_epochs = 20000
	record_period = 200
	η0 = 0.03
	ϵ = 1e-4
	
	X = hcat(D[:,1], ones(length(D[:,1])))
	y = D[:,2]
	w = zeros(size(X)[2])
	H = []
	push!(H, Dict("t"=>0,"a"=>w[1],"b"=>w[2]))
	
	for t in 1:max_epochs
		η = η0 / √t
		i = rand(1:size(X)[1])
	 	ŷ = X[i,:]' * w
		grad =  2 * (ŷ - y[i]) * X[i,:]
		if sum(abs.(grad)) < ϵ
			break
		end
		w -= η*grad
		if t%record_period == 0
			push!(H, Dict("t"=>t, "a"=>w[1], "b"=>w[2]))
		end
	end
	fill_loss_for_checkpoints(H)
	return H
end

# ╔═╡ 95b271c2-3b13-4e13-8bf9-aa32e3b02ceb
HHH = calc_plot_sgd()

# ╔═╡ 713e01dc-aa60-4488-a783-623de4b23533
function plot_animation2(H, ci)
	plot_heatmap(cb=false)
	scatter!([H[1]["a"],], [H[1]["b"],]; shape=:star6, ms=7, c=:white, label="", markerstrokewidth=0)
	for i in 1:ci
		plot!([H[i]["a"], H[i+1]["a"]], [H[i]["b"], H[i+1]["b"]];
			  lw=3, c=:white, label="")
	end
	epoch = H[ci]["t"]
	mse = H[ci]["loss"] |> x -> round(x; digits=5)
	msg = "Epoch #$epoch, MSE = $mse"
	annotate!([(3.0,-0.7,text(msg, 12, :center, :black))])
	plot!()
end

# ╔═╡ aedbbdaa-19fd-4786-ac4d-8b460792c4cf
@bind cii Slider(1:length(HHH)-1, show_value=true)

# ╔═╡ c6c15ab1-1bad-4f10-ad96-798dc9aa6122
let
	p1 = plot_animation2(HHH, cii)
	p2 = plot_regression(HHH, cii)
	
	plot(p1, p2; layout=(@layout [a b]), size=(900,450))
end

# ╔═╡ 240ae292-6310-46a5-81c4-be22093fc667
let
	anim = @animate for i in 1:length(HHH)-1
		p1 = plot_animation2(HHH, i)
		p2 = plot_regression(HHH, i)
	
		plot(p1, p2; layout=(@layout [a b]), size=(900,450))
	end
	gif(anim, "sgd.gif"; fps=2)
end

# ╔═╡ 18113f21-e8a6-42a2-898b-7de075bad646


# ╔═╡ 7c7b1329-d123-4f37-91cd-4898beb0c196
function plot_heatmap2(H,ci;cb=true)
	gr()
	N = 1024
	minvalue = 1e-6     # This prevents log 0 in the logarithmic scale.
	mincontour = 1e-2   # Cut-off value for the contour plot.
	A = range(-1, 7, N)
	B = range(-1, 7, N)
	losses = calc_losses(A, B', D, N, minvalue)

	J_levels = [1, 10.0, 100.0, 1000.0]
	
	plot(xlim=(-1,7), ylim=(-1,7), framestyle=:box, aspect_ratio=1)
	plot!(xticks=-1:7, yticks=-1:7)
	plot!(xlabel="a", ylabel="b", title="Instance #$ci", titlefontsize=10)

	heatmap!(A, B, losses[ci]'; colorbar_scale=:log10, clim=(10^-5,10^3),
		fillcolor=cgrad(:viridis), colorbar=cb )
	contour!(A, B, losses[ci]'; lc=:red, lw=0.5, ls=:dash, levels= J_levels)

	a_, b_ = calc_minimizer(D)
	scatter!([H[1]["a"],], [H[1]["b"],]; shape=:star6, ms=7, c=:white, label="", markerstrokewidth=0)
	scatter!([(a_,b_)]; shape=:star5, ms=7, c=:red, label="", markerstrokewidth=0)
end

# ╔═╡ 1ec91a0c-b077-42d6-af27-936fd4d069d5
let

	p1 = plot_heatmap2(HHH,1;cb=false)
	p2 = plot_heatmap2(HHH,2;cb=false)
	p3 = plot_heatmap2(HHH,3;cb=false)
	p4 = plot_heatmap2(HHH,4;cb=false)
		
	plot(p1, p2, p3, p4; layout=(@layout [a b; c d]), size=(900,900))
end

# ╔═╡ 0c7f3c06-22f2-4e44-b709-5e42d5bdba2e
function minimizer_of_a(D,b)
	x = D[:,1] |> mean
	x2 = D[:,1].^2 |> mean
	xy = D[:,1] .* D[:,2] |> mean
	return (xy - x * b) / x2
end

# ╔═╡ 538c51ee-9003-405a-aecf-8dbc4fe165b9
let
	A = range(-1, 6, length=100)
	b = 0
	losses = [ calc_loss.(D[i,1], D[i,2], A, b) for i in 1:size(D)[1]]
	
	plot(xlim=(-1.5,6.5), ylim=(-25,200), xticks=-1:1:6, yticks=-25:25:200, 	
		framestyle=:box)
	plot!(xlabel="a", ylabel="Loss: Mean Squared Error (MSE)")

	for i in 1:size(D)[1]
		plot!(A, losses[i]; label="Instance #$i", lw=2)
		vline!([])
	end
	plot!()
	
end

# ╔═╡ 6e4f465c-2a2d-4ffb-8391-798a417c651a
D[1:2,1] .* D[1:2,2] |> mean

# ╔═╡ 5354dccc-88ef-4552-b5b1-a68efce1e736
D[:,1] |> mean

# ╔═╡ d466df2c-8cb1-40d2-a671-09b2f644a1a4


# ╔═╡ b8566e06-349d-4469-8887-94aacad92d91


# ╔═╡ 9351f501-62a6-413f-8a1c-1fd1e889831e


# ╔═╡ 6bb18e91-5639-4fde-afae-5884a06d70eb


# ╔═╡ b5604058-ea51-4ef0-a4a2-308f2a8d963c


# ╔═╡ 5838993f-affc-4a19-8a29-6fa22e2aea9b


# ╔═╡ e5349ea7-1f1e-4d0f-aa7e-342f6ad09df7


# ╔═╡ f33c6dad-a3f6-40cd-90fd-34e252af4cca


# ╔═╡ f877a16a-ce53-4979-95b6-5f1f194937c3


# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[compat]
Plots = "~1.25.6"
PlutoUI = "~0.7.30"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.2"
manifest_format = "2.0"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "af92965fb30777147966f58acb05da51c5616b5f"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.3.3"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "4b859a208b2397a7a623a03449e4636bdb17bcf2"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.1+1"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "6e39c91fb4b84dcb870813c91674bdebb9145895"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.11.5"

[[deps.ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "bf98fa45a0a4cee295de98d4c1462be26345b9a1"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.2"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "Colors", "FixedPointNumbers", "Random"]
git-tree-sha1 = "6b6f04f93710c71550ec7e16b650c1b9a612d0b6"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.16.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "024fe24d83e4a5bf5fc80501a314ce0d1aa35597"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.0"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

[[deps.Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "44c37b4636bc54afac5c574d2d02b625349d6582"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.41.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[deps.Contour]]
deps = ["StaticArrays"]
git-tree-sha1 = "9f02045d934dc030edad45944ea80dbd1f0ebea7"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.5.7"

[[deps.DataAPI]]
git-tree-sha1 = "cc70b17275652eb47bc9e5f81635981f13cea5c8"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.9.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "3daef5523dd2e769dad2365274f760ff5f282c7d"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.11"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "b19534d1895d702889b219c382a6e18010797f0b"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.6"

[[deps.Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[deps.EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3f3a2501fa7236e9b911e0f7a588c657e822bb6d"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.2.3+0"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b3bfd02e98aedfa5cf885665493c5598c350cd2f"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.2.10+0"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "Pkg", "Zlib_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "d8a578692e3077ac998b50c0217dfd67f21d1e5f"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.0+0"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "21efd19106a55620a188615da6d3d06cd7f6ee03"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.93+0"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "87eb71354d8ec1a96d4a7636bd57a7347dde3ef9"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.10.4+0"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pkg", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll"]
git-tree-sha1 = "0c603255764a1fa0b61752d2bec14cfbd18f7fe8"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.3.5+1"

[[deps.GR]]
deps = ["Base64", "DelimitedFiles", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Pkg", "Printf", "Random", "RelocatableFolders", "Serialization", "Sockets", "Test", "UUIDs"]
git-tree-sha1 = "4a740db447aae0fbeb3ee730de1afbb14ac798a1"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.63.1"

[[deps.GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Pkg", "Qt5Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "aa22e1ee9e722f1da183eb33370df4c1aeb6c2cd"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.63.1+0"

[[deps.GeometryBasics]]
deps = ["EarCut_jll", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "58bcdf5ebc057b085e58d95c138725628dd7453c"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.4.1"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "a32d672ac2c967f3deb8a81d828afc739c838a06"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.68.3+2"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HTTP]]
deps = ["Base64", "Dates", "IniFile", "Logging", "MbedTLS", "NetworkOptions", "Sockets", "URIs"]
git-tree-sha1 = "0fa77022fe4b511826b39c894c90daf5fce3334a"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "0.9.17"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
git-tree-sha1 = "2b078b5a615c6c0396c77810d92ee8c6f470d238"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.3"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[deps.IniFile]]
deps = ["Test"]
git-tree-sha1 = "098e4d2c533924c921f9f9847274f2ad89e018b8"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "a7254c0acd8e62f1ac75ad24d5db43f5f19f3c65"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.2"

[[deps.IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[deps.IterTools]]
git-tree-sha1 = "fa6287a4469f5e048d763df38279ee729fbd44e5"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.4.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "22df5b96feef82434b07327e2d3c770a9b21e023"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.0"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "8076680b162ada2a031f707ac7b4953e30667a37"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.2"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d735490ac75c5cb9f1b00d8b5509c11984dc6943"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.1.0+0"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.Latexify]]
deps = ["Formatting", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "Printf", "Requires"]
git-tree-sha1 = "a8f4f279b6fa3c3c4f1adadd78a621b13a506bce"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.15.9"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "64613c82a59c120435c067c2b809fc61cf5166ae"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.7+0"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "7739f837d6447403596a75d19ed01fd08d6f56bf"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.3.0+3"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c333716e46366857753e273ce6a69ee0945a6db9"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.42.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "42b62845d70a619f063a7da093d995ec8e15e778"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+1"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Pkg", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "340e257aada13f95f98ee352d316c3bed37c8ab9"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.3.0+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "e5718a00af0ab9756305a0392832c8952c7426c1"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.6"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "3d3e902b31198a27340d0bf00d6ac452866021cf"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.9"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "Random", "Sockets"]
git-tree-sha1 = "1c38e51c3d08ef2278062ebceade0e46cefc96fe"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.0.3"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[deps.Measures]]
git-tree-sha1 = "e498ddeee6f9fdb4551ce855a46f54dbd900245f"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.1"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "bf210ce90b6c9eed32d25dbcae1ebc565df2687f"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.2"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[deps.NaNMath]]
git-tree-sha1 = "f755f36b19a5116bb580de457cda0c140153f283"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "0.3.6"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "648107615c15d4e09f7eca16307bc821c1f718d8"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.13+0"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.PCRE_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b2a7af664e098055a7529ad1a900ded962bca488"
uuid = "2f80f16e-611a-54ab-bc61-aa92de5b98fc"
version = "8.44.0+0"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "92f91ba9e5941fc781fecf5494ac1da87bdac775"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.2.0"

[[deps.Pixman_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b4f5d02549a10e20780a24fce72bea96b6329e29"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.40.1+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[deps.PlotThemes]]
deps = ["PlotUtils", "Requires", "Statistics"]
git-tree-sha1 = "a3a964ce9dc7898193536002a6dd892b1b5a6f1d"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "2.0.1"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "Printf", "Random", "Reexport", "Statistics"]
git-tree-sha1 = "68604313ed59f0408313228ba09e79252e4b2da8"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.1.2"

[[deps.Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "GeometryBasics", "JSON", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "PlotThemes", "PlotUtils", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "UUIDs", "UnicodeFun", "Unzip"]
git-tree-sha1 = "db7393a80d0e5bef70f2b518990835541917a544"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.25.6"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "5c0eb9099596090bb3215260ceca687b888a1575"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.30"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "2cf929d64681236a2e074ffafb8d568733d2e6af"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.2.3"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Qt5Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "xkbcommon_jll"]
git-tree-sha1 = "ad368663a5e20dbb8d6dc2fddeefe4dae0781ae8"
uuid = "ea2cea3b-5b76-57ae-a6ef-0a8af62496e1"
version = "5.15.3+0"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.RecipesBase]]
git-tree-sha1 = "6bf3f380ff52ce0832ddd3a2a7b9538ed1bcca7d"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.2.1"

[[deps.RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "RecipesBase"]
git-tree-sha1 = "37c1631cb3cc36a535105e6d5557864c82cd8c2b"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.5.0"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "cdbd3b1338c72ce29d9584fdbe9e9b70eeb5adca"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "0.1.3"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "0b4b7f1393cff97c33891da2a0bf69c6ed241fda"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "2ae4fe21e97cd13efd857462c1869b73c9f61be3"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.3.2"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StatsAPI]]
git-tree-sha1 = "d88665adc9bcf45903013af0982e2fd05ae3d0a6"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.2.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "51383f2d367eb3b444c961d485c565e4c0cf4ba0"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.14"

[[deps.StructArrays]]
deps = ["Adapt", "DataAPI", "StaticArrays", "Tables"]
git-tree-sha1 = "d21f2c564b21a202f4677c0fba5b5ee431058544"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.4"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "TableTraits", "Test"]
git-tree-sha1 = "bb1064c9a84c52e277f1096cf41434b675cd368b"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.6.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.URIs]]
git-tree-sha1 = "97bbe755a53fe859669cd907f2d96aee8d2c1355"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.3.0"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Unzip]]
git-tree-sha1 = "34db80951901073501137bdbc3d5a8e7bbd06670"
uuid = "41fe7b60-77ed-43a1-b4f0-825fd5a5650d"
version = "0.1.2"

[[deps.Wayland_jll]]
deps = ["Artifacts", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "3e61f0b86f90dacb0bc0e73a0c5a83f6a8636e23"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.19.0+0"

[[deps.Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "66d72dc6fcc86352f01676e8f0f698562e60510f"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.23.0+0"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "1acf5bdf07aa0907e0a37d3718bb88d4b687b74a"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.9.12+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "5be649d550f3f4b95308bf0183b82e2582876527"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.6.9+4"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4e490d5c960c314f33885790ed410ff3a94ce67e"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.9+4"

[[deps.Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fe47bd2247248125c428978740e18a681372dd4"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.3+4"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

[[deps.Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "0e0dc7431e7a0587559f9294aeec269471c991a4"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "5.0.3+4"

[[deps.Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "89b52bc2160aadc84d707093930ef0bffa641246"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.7.10+4"

[[deps.Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll"]
git-tree-sha1 = "26be8b1c342929259317d8b9f7b53bf2bb73b123"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.4+4"

[[deps.Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "34cea83cb726fb58f325887bf0612c6b3fb17631"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.2+4"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6783737e45d3c59a4a4c4091f5f88cdcf0908cbb"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.0+3"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "daf17f441228e7a3833846cd048892861cff16d6"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.13.0+3"

[[deps.Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "926af861744212db0eb001d9e40b5d16292080b2"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.0+4"

[[deps.Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[deps.Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[deps.Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "4bcbf660f6c2e714f87e960a171b119d06ee163b"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.2+4"

[[deps.Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "5c8424f8a67c3f2209646d4425f3d415fee5931d"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.27.0+4"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "79c31e7844f6ecf779705fbc12146eb190b7d845"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.4.0+3"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "cc4bf3fdde8b7e3e9fa0351bdeedba1cf3b7f6e6"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.0+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "5982a94fcba20f02f42ace44b9894ee2b140fe47"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.1+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "b910cb81ef3fe6e78bf6acee440bda86fd6ae00c"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"

[[deps.xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "ece2350174195bb31de1a63bea3a41ae1aa593b6"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "0.9.1+5"
"""

# ╔═╡ Cell order:
# ╠═d7ac6a44-843f-48da-b90d-576658f33d84
# ╠═f7fd08ce-78fb-11ec-2e93-5bcd26561b10
# ╠═673191fe-f287-453a-b396-28a234132f11
# ╠═e114148e-10a1-4d42-89ea-1b41c5c2393b
# ╠═5c5e89e7-69d6-40d6-a340-834338c18c8b
# ╠═74fa366c-e9b9-4668-8ac5-b82090e47006
# ╠═5fbd3837-49a0-44f2-973e-9d15dbf5bc43
# ╠═3066a735-924f-437f-a67c-1632c14d86a9
# ╠═f98e68cd-ffcc-4c73-890a-2cf34a828237
# ╠═a1a399f0-6a95-4003-879a-11cc0fc86049
# ╠═368c6ea8-1aa8-4c38-8700-73c79c74bac9
# ╠═6f5ecb62-c5d0-48aa-89a2-bee19cb2db4e
# ╠═f51adce8-b749-4453-b9c9-849e874c45ee
# ╠═0289da34-98e8-4d4e-8243-00d48147c432
# ╠═2205b8cf-10d9-4594-82c2-20f92753c91c
# ╠═bdfac505-181f-489a-aaf5-f90d06f9f685
# ╠═6c1d8bdc-2d10-4185-9118-505f1044cf52
# ╠═c69d0f2d-7b30-4210-a90e-321874edca46
# ╠═6f9ef0b1-a92d-47f2-b0b8-cdf4067ee010
# ╠═17c6fd35-36c3-492e-966b-0f49428c24a6
# ╠═83c82cfc-b23c-414f-99a0-f77172f317b2
# ╠═2c74a643-2db6-4693-bd46-47560b7036fb
# ╠═403cb46f-f640-4bb9-8708-2ab6d209445b
# ╠═ae3bbea4-d7dc-42f7-bf25-17378089265d
# ╠═13380627-fc87-4245-816f-c2cb4b647db1
# ╠═0dcd1a01-5ed1-4930-8f6f-b09c619b09e2
# ╠═3795afa6-1705-44be-b4bf-1adbcf29e91b
# ╠═247e18dd-8298-444a-ab32-c977b2a94996
# ╠═e69398f4-23ec-4b2c-bb15-69451d0c86ae
# ╠═188fdc2e-be02-43d5-bf94-dcf527a47d66
# ╠═181d24d0-5d9b-4436-9f87-fc518e4a9504
# ╠═ffbf158e-8a33-4179-b2ce-95e08cb5911e
# ╠═4ed5272a-6442-4a61-af37-fcca09d9f45a
# ╠═2dc05c65-d8a4-4539-8650-40f457b0ff13
# ╠═fff206d6-ea3a-49b0-b90b-7a04afb24fb7
# ╠═4abdbcdd-bd81-4c01-a984-dd6ee1b64632
# ╠═95b271c2-3b13-4e13-8bf9-aa32e3b02ceb
# ╠═713e01dc-aa60-4488-a783-623de4b23533
# ╠═c6c15ab1-1bad-4f10-ad96-798dc9aa6122
# ╠═aedbbdaa-19fd-4786-ac4d-8b460792c4cf
# ╠═240ae292-6310-46a5-81c4-be22093fc667
# ╠═18113f21-e8a6-42a2-898b-7de075bad646
# ╠═7c7b1329-d123-4f37-91cd-4898beb0c196
# ╠═1ec91a0c-b077-42d6-af27-936fd4d069d5
# ╠═0c7f3c06-22f2-4e44-b709-5e42d5bdba2e
# ╠═538c51ee-9003-405a-aecf-8dbc4fe165b9
# ╠═6e4f465c-2a2d-4ffb-8391-798a417c651a
# ╠═5354dccc-88ef-4552-b5b1-a68efce1e736
# ╠═d466df2c-8cb1-40d2-a671-09b2f644a1a4
# ╠═b8566e06-349d-4469-8887-94aacad92d91
# ╠═9351f501-62a6-413f-8a1c-1fd1e889831e
# ╠═6bb18e91-5639-4fde-afae-5884a06d70eb
# ╠═b5604058-ea51-4ef0-a4a2-308f2a8d963c
# ╠═5838993f-affc-4a19-8a29-6fa22e2aea9b
# ╠═e5349ea7-1f1e-4d0f-aa7e-342f6ad09df7
# ╠═f33c6dad-a3f6-40cd-90fd-34e252af4cca
# ╠═f877a16a-ce53-4979-95b6-5f1f194937c3
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002